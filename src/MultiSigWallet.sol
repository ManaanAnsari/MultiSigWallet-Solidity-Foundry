// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

contract MultiSigWallet {
    event Deposit(address indexed owner, uint256 indexed amount);
    event SubmitTransaction(
        address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    address[] public s_owners;
    mapping(address => bool) public s_isOwner;
    uint256 public s_numConfirmationsRequired;

    Transaction[] public s_transactions;
    mapping(uint256 => mapping(address => bool)) public s_confirmations;

    constructor(address[] memory owners, uint256 numConfirmationsRequired) {
        require(owners.length > 0, "Owners required");
        require(
            numConfirmationsRequired > 0 && numConfirmationsRequired <= owners.length, "Invalid number of confirmations"
        );

        for (uint256 i = 0; i < owners.length; i++) {
            address owner = owners[i];

            require(owner != address(0), "Invalid owner");
            require(!s_isOwner[owner], "Owner not unique");

            s_isOwner[owner] = true;
            s_owners.push(owner);
        }

        s_numConfirmationsRequired = numConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submitTransaction(address to, uint256 value, bytes memory data) public {
        require(s_isOwner[msg.sender], "Not an owner");

        s_transactions.push(Transaction({to: to, value: value, data: data, executed: false, numConfirmations: 0}));
        uint256 txIndex = s_transactions.length - 1;

        emit SubmitTransaction(msg.sender, txIndex, to, value, data);
    }

    function confirmTransaction(uint256 txIndex) public {
        require(s_isOwner[msg.sender], "Not an owner");
        require(txIndex < s_transactions.length, "Invalid transaction");

        require(!s_confirmations[txIndex][msg.sender], "Transaction already confirmed");

        s_confirmations[txIndex][msg.sender] = true;
        s_transactions[txIndex].numConfirmations += 1;

        emit ConfirmTransaction(msg.sender, txIndex);
    }

    function revokeConfirmation(uint256 txIndex) public {
        require(s_isOwner[msg.sender], "Not an owner");
        require(txIndex < s_transactions.length, "Invalid transaction");

        require(s_confirmations[txIndex][msg.sender], "Transaction not confirmed");

        s_confirmations[txIndex][msg.sender] = false;
        s_transactions[txIndex].numConfirmations -= 1;

        emit RevokeConfirmation(msg.sender, txIndex);
    }

    function executeTransaction(uint256 txIndex) public {
        require(s_isOwner[msg.sender], "Not an owner");
        require(txIndex < s_transactions.length, "Invalid transaction");

        Transaction storage transaction = s_transactions[txIndex];

        require(!transaction.executed, "Transaction already executed");
        require(transaction.numConfirmations >= s_numConfirmationsRequired, "Not enough confirmations");

        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "Transaction failed");

        emit ExecuteTransaction(msg.sender, txIndex);
    }
}

contract SimpleStorage {
    uint256 public s_storage;
    address public s_owner;

    constructor(address _owner) {
        s_owner = _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner, "You are not the owner");
        _;
    }

    function store(uint256 _storage) public onlyOwner {
        s_storage = _storage;
    }
}
