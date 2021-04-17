pragma solidity >=0.7.0 <0.9.0;

contract healthSys {
    
    // tax to be issued for each transaction
    uint8 public tax;
    // the total tokens offered by data pool
    uint8 public totalTokens;
    // the total amount of payment
    uint256 public payment;
    // the 564 team
    address public issuer;
    // the third party data buyer
    address public buyer;
    // the data providers and the issuer
    address[] public accounts;
    // the name of the token
    string public name;
    // the symbol of the token
    string public symbol;
    
    // distributed revenue account balance
    mapping (address => uint256) public revenues;
    // addresses mapped to token balance
    mapping (address => uint256) public shares;

    // events
    event CurrentBuyer (address account);
    event AddAccount (address account);
    event RemoveAccount (address account);
    event ChangedTax (uint8 tax);
    event RevenuesDistributed (address account, uint256 etherReceived, uint256 totalRevenue);
    event DataPurchased (address buyer, uint256 amountPaid, uint256 taxGain, uint256 revenueGain);



    // constructor
    constructor (string memory _name, string memory _symbol, uint8 _tax, uint8 _totalTokens) {
        issuer = msg.sender;
        name = _name;
        symbol = _symbol;
        setTax(_tax);
        totalTokens = _totalTokens;
        accounts.push(issuer);
    }
    
    
    
    
    
    // check if msg is from ourside
    modifier isIssuer {
        require(msg.sender == issuer);
        _;
    }
    // check if msg is from third party buyer
    modifier isBuyer {
        require(msg.sender == buyer);
        _;
    }
    
    
    
    
    // check if account is system
    function contains (address _account) public view returns (bool, uint256) {
        for (uint256 i = 0; i < accounts.length; i++) {
            if (_account == accounts[i]) return (true, i);
        }
        return (false, 0);
    }
    // return the share of each account/user
    function sharesOf (address _owner) public view returns (uint256 balance) {
        return shares[_owner];
    }
    // return undistributed tokens
    function tokenLeft () public view returns (uint256 balance) {
        uint256 _total = totalTokens;
        for (uint256 i = 0; i < accounts.length; i++) {
            _total -= sharesOf(accounts[i]);
        }
        return _total;
    }
    // add an account to the system
    function addAccount(address _account) public isIssuer {
        (bool _contains, ) = contains(_account);
        if (!_contains) accounts.push(_account);
        emit AddAccount (_account);
    }
    // remove an account from the system
    function removeAccount(address _account) public isIssuer {
        (bool _contains, uint256 i) = contains(_account);
        if (_contains) {
            accounts[i] = accounts[accounts.length - 1];
            accounts.pop();
        }
        emit RemoveAccount (_account);
    }
    // set buyer to decide who can by the data
    function setBuyer(address _buyer) public isIssuer {
        buyer = _buyer;
        emit CurrentBuyer(buyer);
    }
    // set tax
    function setTax (uint8 _tax) public isIssuer {
        require( _tax <= 100, "Tax Rate should be in range of 0% to 100%");
        tax = _tax;
        emit ChangedTax (tax);
    }
    // give the user shares for their personal info
    function setShares (address _account, uint256 share) public isIssuer {
        (bool _contains, ) = contains(_account);
        if (_contains && tokenLeft() > share) {
            shares[_account] += share;
        }
    }
    // execute the payment/transaction
    function distribute() public isIssuer {
        uint256 _payment = payment;
        uint256 undistributedToken = tokenLeft();
        // issuer receives the undistributed money
        uint256 issuerEtherReceived = _payment * undistributedToken / totalTokens;
        revenues[issuer] += issuerEtherReceived;
        payment -= issuerEtherReceived;
        emit RevenuesDistributed(issuer, issuerEtherReceived, revenues[issuer]);
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint256 _shares = sharesOf(account);
            uint256 etherReceived = _payment * _shares / totalTokens;
            revenues[account] += etherReceived;
            payment -= etherReceived;
            emit RevenuesDistributed(account, etherReceived, revenues[account]);
        }
    }
    // Buyer buys data
    function payForData() public payable isBuyer {
        // 1:1 payment for better calculate
        uint256 payment = totalTokens;
        require (msg.value == payment);
        uint256 taxGain = msg.value * tax / 100;
        payment += msg.value - taxGain;
        revenues[issuer] += taxGain;
        emit DataPurchased(msg.sender, msg.value, taxGain, msg.value - taxGain);
    }
    
    // // return ether back to origin
    // receive() external payable {
    //     (msg.sender).transfer(msg.value);   
    // }
}
