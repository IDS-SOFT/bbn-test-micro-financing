// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MicrofinancingContract is Ownable {
    IERC20 public lendingToken; // The token to be lent
    uint256 public interestRate; // Annual interest rate (in percentage)
    uint256 public loanTerm; // Term of each loan (in seconds)

    struct Loan {
        address borrower;
        uint256 amount;
        uint256 startTime;
        uint256 repaymentTime;
        uint256 interest;
        bool repaid;
    }

    Loan[] public loans;
    uint256 public totalLoans;

    mapping(address => uint256) public borrowerLoanCount;
    mapping(address => uint256) public borrowerTotalDebt;

    event LoanIssued(address indexed borrower, uint256 loanId, uint256 amount, uint256 interest);
    event LoanRepaid(address indexed borrower, uint256 loanId, uint256 amount);
    event CheckBalance(string text, uint amount);

    // Uncomment the constructor and complete argument details in scripts/deploy.ts to deploy the contract with arguments

    // constructor(
    //     address _lendingToken,
    //     uint256 _initialInterestRate,
    //     uint256 _initialLoanTerm
    // ) {
    //     lendingToken = IERC20(_lendingToken);
    //     interestRate = _initialInterestRate;
    //     loanTerm = _initialLoanTerm;
    // }

    function issueLoan(uint256 amount) external {
        require(amount > 0, "Loan amount must be greater than zero");

        uint256 interest = (amount * interestRate * loanTerm) / (365 days * 100);
        uint256 repaymentTime = block.timestamp + loanTerm;

        Loan memory newLoan = Loan({
            borrower: msg.sender,
            amount: amount,
            startTime: block.timestamp,
            repaymentTime: repaymentTime,
            interest: interest,
            repaid: false
        });

        loans.push(newLoan);
        borrowerLoanCount[msg.sender]++;
        borrowerTotalDebt[msg.sender] += amount + interest;
        totalLoans++;

        require(lendingToken.transferFrom(msg.sender, address(this), amount + interest), "Token transfer failed");

        emit LoanIssued(msg.sender, loans.length - 1, amount, interest);
    }

    function repayLoan(uint256 loanId) external {
        require(loanId < loans.length, "Invalid loan ID");
        Loan storage loan = loans[loanId];

        require(msg.sender == loan.borrower, "Only the borrower can repay the loan");
        require(!loan.repaid, "Loan is already repaid");
        require(block.timestamp <= loan.repaymentTime, "Loan is overdue");

        lendingToken.transfer(owner(), loan.amount);
        lendingToken.transfer(loan.borrower, loan.interest);

        loan.repaid = true;
        borrowerTotalDebt[msg.sender] -= loan.amount + loan.interest;

        emit LoanRepaid(msg.sender, loanId, loan.amount);
    }
    
    function getBalance(address user_account) external returns (uint){
    
       string memory data = "User Balance is : ";
       uint user_bal = user_account.balance;
       emit CheckBalance(data, user_bal );
       return (user_bal);

    }
}

