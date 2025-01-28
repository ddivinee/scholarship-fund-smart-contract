# Scholarship Fund Smart Contract

A Clarity smart contract for managing a decentralized scholarship fund system on the Stacks blockchain. This contract enables transparent management of scholarship funds, allowing donors to contribute, board members to manage student allocations, and students to withdraw their awarded scholarships.

## Features

- **Secure Fund Management**: Track and manage scholarship funds with automated disbursement controls
- **Role-Based Access**: Designated board chair controls administrative functions
- **Flexible Contribution System**: Configurable minimum and maximum contribution limits
- **Student Management**: Add, update, and remove student allocations
- **Safety Controls**: Emergency halt functionality and frozen state management
- **Transparency**: Full audit trail of all transactions and changes
- **Time-Locked Withdrawals**: 24-hour cooldown period between disbursements
- **Contribution Returns**: Allow donors to request returns within specified timeframes

## Contract Functions

### Administrative Functions

- `transfer-chair`: Transfer board chair authority to a new principal
- `set-contribution-limits`: Update minimum and maximum contribution amounts
- `set-frozen`: Toggle contract frozen state
- `emergency-halt`: Immediately freeze all contract operations

### Student Management

- `add-student`: Add a new student with specified allocation
- `update-student-allocation`: Modify existing student's allocation
- `remove-student`: Remove a student from the system
- `confirm-student-removal`: Two-step confirmation for student removal

### Financial Operations

- `contribute`: Accept contributions from donors
- `withdraw-funds`: Allow students to withdraw allocated funds
- `request-contribution-return`: Process donor refund requests

### Read-Only Functions

- `get-contribution`: View contribution amount for specific donor
- `get-pool-total`: Get total funds in scholarship pool
- `is-frozen`: Check if contract operations are frozen
- `get-student-allocation`: View allocation for specific student
- `get-board-chair`: Get current board chair address
- `get-donor-history`: Retrieve contribution and disbursement history

## Error Codes

- `u1`: Not authorized
- `u2`: Invalid scholarship amount
- `u3`: Insufficient funds
- `u4`: Student not found
- `u5`: Student already exists
- `u8`: Action not confirmed
- `u9`: No state change
- `u100`: Invalid contribution or contract frozen
- `u101`: Unauthorized or invalid student input
- `u102`: Invalid withdrawal or cooldown period not met
- `u104`: Invalid contribution limits
- `u105`: Unauthorized emergency action
- `u110`: Invalid refund request

## Usage Example

```clarity
;; Contributing to the scholarship fund
(contract-call? .scholarship-fund contribute u1000)

;; Adding a new student (board chair only)
(contract-call? .scholarship-fund add-student 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u5000)

;; Student withdrawing funds
(contract-call? .scholarship-fund withdraw-funds u1000)
```

## Security Considerations

1. All administrative functions are restricted to the board chair
2. Two-step confirmation required for critical operations
3. Time-locked withdrawals prevent rapid fund drainage
4. Emergency halt mechanism for crisis management
5. Contribution limits prevent extreme donations
6. All state changes are logged for transparency

## Contract Deployment

To deploy this contract:

1. Ensure you have the [Clarinet](https://github.com/hirosystems/clarinet) development environment set up
2. Deploy using a sufficient amount of STX for contract deployment
3. Initialize the board chair address during deployment
4. Set initial contribution limits
5. Add initial students if needed


For questions or support, please open an issue in the repository or contact the development team.