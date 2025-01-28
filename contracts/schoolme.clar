;; Scholarship Fund Smart Contract
;; This smart contract implements a decentralized scholarship management system
;; that enables transparent fund distribution and management.
;; 
;; Key features:
;; - Secure fund management with time-locked withdrawals
;; - Role-based access control with board chair oversight
;; - Student allocation tracking and management
;; - Emergency controls and safety measures
;; - Transparent contribution and disbursement system


;; Constants
;; Error codes for various contract operations
(define-constant ERR_NOT_AUTHORIZED (err u1))    ;; When caller lacks necessary permissions
(define-constant ERR_INVALID_SCHOLARSHIP (err u2))    ;; When scholarship amount is invalid
(define-constant ERR_NO_FUNDS (err u3))    ;; When attempting operations with insufficient funds
(define-constant ERR_STUDENT_NOT_FOUND (err u4))    ;; When referenced student doesn't exist
(define-constant ERR_STUDENT_EXISTS (err u5))    ;; When attempting to add an existing student
(define-constant ERR_NO_CONFIRMATION (err u8))    ;; When confirmation is required but not provided
(define-constant ERR_NO_CHANGE (err u9))    ;; When operation would result in no state change
(define-constant disbursement-wait-period u86400) ;; 24-hour cooldown period between disbursements


;; State Variables
;; Core contract state tracking
(define-data-var scholarship-pool uint u0)           ;; Total available funds in the contract
(define-data-var board-chair principal tx-sender)    ;; Address of the current board chair
(define-data-var min-contribution uint u1)           ;; Minimum allowed contribution amount
(define-data-var max-contribution uint u1000000000)  ;; Maximum allowed contribution amount
(define-data-var frozen bool false)                  ;; Emergency freeze switch for contract


;; Data Maps
;; Track all financial and participant data
(define-map contributions principal uint)      ;; Maps donors to their total contributions
(define-map students principal uint)           ;; Maps students to their allocated amounts
(define-map last-disbursement principal uint)  ;; Tracks last withdrawal time for each student


;; Private Functions
;; Helper function to process scholarship disbursement to a student
(define-private (disburse-to-student (student-data {student: principal, amount: uint}))
  (let ((student (get student student-data))
        (amount (get amount student-data)))
    (try! (as-contract (stx-transfer? amount tx-sender student)))
    (print {event: "scholarship-disbursed", student: student, amount: amount})
    (ok true)
  )
)

;; Public Functions
;; Process a new contribution to the scholarship fund
(define-public (contribute (amount uint))
  (if (and (not (var-get frozen))
           (>= amount (var-get min-contribution))
           (<= amount (var-get max-contribution)))
    (begin
      (map-set contributions tx-sender (+ (get-contribution tx-sender) amount))
      (var-set scholarship-pool (+ (var-get scholarship-pool) amount))
      (print {event: "contribution", donor: tx-sender, amount: amount})
      (ok amount)
    )
    (err u100) 
  )
)

;; Add a new student to the scholarship system
(define-public (add-student (student principal) (amount uint))
  (if (and (is-eq tx-sender (var-get board-chair))
           (is-none (map-get? students student))
           (> amount u0))
    (begin
      (map-set students student amount)
      (print {event: "student-added", student: student, amount: amount})
      (ok (tuple (student student) (amount amount)))
    )
    (err u101)
  )
)

;; Process a withdrawal request from a student
(define-public (withdraw-funds (amount uint))
  (let (
    (student-allocation (default-to u0 (map-get? students tx-sender)))
    (last-withdrawal-time (default-to u0 (map-get? last-disbursement tx-sender)))
    (current-time (unwrap-panic (get-block-info? time u0)))
  )
    (if (and (not (var-get frozen))
             (> student-allocation u0)
             (>= student-allocation amount)
             (>= (- current-time last-withdrawal-time) disbursement-wait-period))
      (begin
        (map-set students tx-sender (- student-allocation amount))
        (var-set scholarship-pool (- (var-get scholarship-pool) amount))
        (map-set last-disbursement tx-sender current-time)
        (print {event: "withdrawal", student: tx-sender, amount: amount})
        (as-contract (stx-transfer? amount tx-sender 'ST000000000000000000002AMW42H))
      )
      (err u102)
    )
  )
)

;; Transfer board chair authority to a new address
(define-public (transfer-chair (new-chair principal))
  (let ((current-chair (var-get board-chair)))
    (begin
      (asserts! (is-eq tx-sender current-chair) ERR_NOT_AUTHORIZED)
      (asserts! (not (is-eq new-chair current-chair)) (err u6))
      (var-set board-chair new-chair)
      (ok new-chair)
    )
  )
)

;; Update the minimum and maximum contribution limits
(define-public (set-contribution-limits (new-min uint) (new-max uint))
  (if (and (is-eq tx-sender (var-get board-chair)) (< new-min new-max))
    (begin
      (var-set min-contribution new-min)
      (var-set max-contribution new-max)
      (print {event: "contribution-limits-updated", min: new-min, max: new-max})
      (ok true)
    )
    (err u104)
  )
)

;; Toggle the frozen state of the contract
(define-public (set-frozen (new-frozen-state bool))
  (let ((current-frozen-state (var-get frozen)))
    (begin
      (asserts! (is-eq tx-sender (var-get board-chair)) ERR_NOT_AUTHORIZED)
      (asserts! (not (is-eq new-frozen-state current-frozen-state)) ERR_NO_CHANGE)
      (var-set frozen new-frozen-state)
      (print {event: "contract-status-changed", frozen: new-frozen-state})
      (ok new-frozen-state)
    )
  )
)

;; Update the allocation amount for an existing student
(define-public (update-student-allocation (student principal) (new-amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get board-chair)) ERR_NOT_AUTHORIZED)
    (asserts! (> new-amount u0) ERR_INVALID_SCHOLARSHIP)
    (asserts! (is-some (map-get? students student)) ERR_STUDENT_NOT_FOUND)
    (ok (map-set students student new-amount))
  )
)

;; Remove a student from the scholarship system
(define-public (remove-student (student principal))
  (begin
    (asserts! (is-eq tx-sender (var-get board-chair)) ERR_NOT_AUTHORIZED)
    (asserts! (is-some (map-get? students student)) ERR_STUDENT_NOT_FOUND)
    (map-delete students student)
    (ok true)
  )
)

;; Confirm and execute student removal with additional safety check
(define-public (confirm-student-removal (student principal) (confirm bool))
  (begin
    (asserts! (is-eq tx-sender (var-get board-chair)) ERR_NOT_AUTHORIZED)
    (asserts! confirm ERR_NO_CONFIRMATION)
    (asserts! (is-some (map-get? students student)) ERR_STUDENT_NOT_FOUND)
    (map-delete students student)
    (print {event: "student-removed", student: student})
    (ok true)
  )
)

;; Process a contribution return request
(define-public (request-contribution-return (amount uint))
  (let ((contribution (get-contribution tx-sender))
        (current-time (unwrap-panic (get-block-info? time u0))))
    (if (and (<= amount contribution) 
             (>= (- current-time (unwrap-panic (get-block-info? time u0))) disbursement-wait-period))
      (begin
        (map-set contributions tx-sender (- contribution amount))
        (var-set scholarship-pool (- (var-get scholarship-pool) amount))
        (as-contract (stx-transfer? amount tx-sender 'ST000000000000000000002AMW42H))
      )
      (err u110) ;; Invalid return request
    )
  )
)

;; Emergency function to immediately freeze all contract operations
(define-public (emergency-halt)
  (if (is-eq tx-sender (var-get board-chair))
    (begin
      (var-set frozen true)
      (print {event: "emergency-halt", chair: tx-sender})
      (ok true)
    )
    (err u105) ;; Unauthorized emergency action
  )
)

;; Record an activity in the contract's audit log
(define-public (record-activity (activity-type (string-ascii 32)) (user principal))
  (let ((current-time (unwrap-panic (get-block-info? time u0))))
    (ok true)
  )
)

;; Read-Only Functions
;; Get the total contribution amount for a specific donor
(define-read-only (get-contribution (donor principal))
  (default-to u0 (map-get? contributions donor))
)

;; Get the total amount in the scholarship pool
(define-read-only (get-pool-total)
  (ok (var-get scholarship-pool))
)

;; Check if the contract is currently frozen
(define-read-only (is-frozen)
  (ok (var-get frozen))
)

;; Get the allocation amount for a specific student
(define-read-only (get-student-allocation (student principal))
  (ok (default-to u0 (map-get? students student)))
)

;; Get the current board chair's address
(define-read-only (get-board-chair)
  (ok (var-get board-chair))
)

;; Get complete history for a donor
(define-read-only (get-donor-history (donor principal))
  (ok (tuple (contributions (map-get? contributions donor)) (disbursements (map-get? last-disbursement donor))))
)