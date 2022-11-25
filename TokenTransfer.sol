pragma solidity 0.8.7;

// A simple contract for managing the sending of funds between addresses
// The contracts allows for the minting of balances, burning balance, sending balance to other users
// and managing a list of approved addresses that allow an address to send funds from another address if approved
contract TokenTransfer {
    address public owner;
    mapping(address => uint256) public holders;
    mapping(address => address[]) public approvedSenders;
    mapping(address=>bool) public blacklistedAddresses;

    constructor(uint256 amount) {
        owner = msg.sender;
        holders[msg.sender] = amount;
    }

    function mintTokens(uint256 amount) public restricted {
        holders[msg.sender] += amount;
    }

    function transferTokens(address receiver, uint256 amount) public isNotBlacklisted {
        require(msg.sender != receiver, "Cannot send tokens to yourself!");
        require(holders[msg.sender] >= amount, "You don't have enough tokens to send!");
        holders[msg.sender] -= amount;
        holders[receiver] += amount;
    }

    function burnTokens(uint amount) public restricted {
        require(holders[msg.sender] >= amount, "You don't have enough tokens to burn!");
        holders[msg.sender] -= amount;
    }

    function addApprover(address approver) public isNotBlacklisted {
        require(msg.sender != approver, "You cannot add yourself to your approver list!");
        approvedSenders[msg.sender].push(approver);
    }

    // Finds the index of the address to be removed, overwrites that index with the last value in the array
    // and then remove the previous value
    //E.G. [a, b, c, d].removeApprover[b] = [a, d, c]
    function removeApprover(address approver) public isNotBlacklisted returns (uint256) {
        address[] memory approved = approvedSenders[msg.sender];
        for (uint256 i; i < approved.length; i++) {
            if (approved[i] == approver) {
                approvedSenders[msg.sender][i] = approvedSenders[msg.sender][approvedSenders[msg.sender].length];
                approvedSenders[msg.sender].pop();
                break;
            }
        }
    }

    // Ensure that msg.sender is in the from address approved addres list
    function checkIfExists(address from) private view returns (bool) {
        address[] memory approved = approvedSenders[from];
        for (uint256 i; i < approved.length; i++) {
            if (approved[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    // Transfer funds from another address, only if the msg.sender is approved by the from address
    function transferFrom(uint256 amount, address from, address to) public {
        require(
            checkIfExists(from),
            "Address needs to be in your approved list"
        );
        require(
            holders[from] >= amount,
            "from address doesn't have enough balance"
        );
        require(
            from != to,
            "Cannot send tokens from one address to the same address"
        );
        holders[from] -= amount;
        holders[to] += amount;
    }

    // Blacklist an address: Blacklisted address is unable to transfer funds, etc
    // and approved addresses are removed, esentially freezing the funds within that account
    function blacklistAddress(address blacklisted) public restricted {
        blacklistedAddresses[blacklisted] = true;
        for (uint256 i; i < approvedSenders[blacklisted].length; i++) {
            approvedSenders[blacklisted].pop(); 
        }
    }

    modifier restricted() {
        require(msg.sender == owner);
        _;
    }

    modifier isNotBlacklisted() {
        require(!blacklistedAddresses[msg.sender], "You are blacklisted, get out of here!");
        _;
    }
}
