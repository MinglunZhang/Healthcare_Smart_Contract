// Author:  Minglun Zhang
// Other team members:
//          Ruofan Shen
//          Manmit Singh
//          Haozhan Sun
//          Brenda Wang
//          Yajie Zhang

pragma solidity >=0.7.0 <0.9.0;

// fintech 564 project
contract DataSellApp {
    
    // how we make profits
    uint public tax_rate;
    // how much ether is paid
    uint public balance;
    // the total number of token distributed
    uint public tokens;
    // how many tokens undistributed
    uint public tokens_left;
    // name of the token
    string public name;
    // symbol of the token
    string public symbol;
    // the address of contract issuer
    address public issuer;
    // the address of data buyer
    address public buyer;
    // the addresses of data seller
    address[] public providers;
    // record ether balance for everyone
    mapping (address => uint) public balance_book;
    // record token balance for everyone
    mapping (address => uint) public token_book;
    
    // constructor of the program
    // tokens should be set at 100 as 100% of the data pool ownership
    constructor (string memory _name, string memory _symbol, uint _tax_rate, uint _tokens) {
        require( _tax_rate <= 100, "Tax Rate should be in range of 0% to 100%");
        require( _tokens > 1, "Token number should be greater than 1");
        name = _name;
        symbol = _symbol;
        // we are currently non-profit organization
        tax_rate = 0;
        tokens = _tokens;
        tokens_left = tokens;
        balance = 0;
        issuer = msg.sender;
    }
    
    // check if the msg sender is the issuer
    modifier isIssuer {
        require(msg.sender == issuer, "not the issuer");
        _;
    }
    
    // check if the msg sender is the buyer
    modifier isBuyer {
        require(msg.sender == buyer, "not the buyer");
        _;
    }
    
    // set the address of buyer
    function setBuyer (address _address) public isIssuer {
        buyer = _address;
    }
    
    // check if the seller is already in the contract
    function existProvider (address _address) public view returns (bool, uint) {
        for (uint i = 0; i < providers.length; i++) {
            if (_address == providers[i]) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    
    // add a new seller
    function addProvider (address _address) public isIssuer {
        (bool exist, ) = existProvider(_address);
        if (!exist) {
            providers.push(_address);
        }
    }
    
    // remove a seller: not used right now
    function removeProvider (address _address) public isIssuer {
        (bool exist, uint idx) = existProvider(_address);
        if (exist) {
            providers[idx] = providers[providers.length - 1];
            providers.pop();
        }
    }
    
    // assign tokens to one seller based on the value of data he/she sells
    function tradeData (address _address, uint data_value) public isIssuer {
        (bool exist, ) = existProvider(_address);
        if (exist && data_value <= tokens_left) {
            token_book[_address] += data_value;
            tokens_left -= data_value;
        }
    }
    
    // buyer pay for the data
    // tax is not implemented
    // but we do collect undistributed balance in our wallet :)
    function pay () public payable isBuyer {
        balance = msg.value;
        // distribute to every providers
        for (uint i = 0; i < providers.length; i++) {
            address account = providers[i];
            uint token = token_book[account];
            uint paid = balance * token / tokens;
            balance = balance - paid;
            balance_book[account] = paid;
            token_book[account] = 0;
        }
        balance_book[issuer] = balance;
        balance = 0;
    }
    
    // withdraw ether to wallet
    function withdraw () public payable {
        (bool exist, ) = existProvider(msg.sender);
        if (exist || msg.sender == issuer) {
            uint amount = balance_book[msg.sender];
            (msg.sender).transfer(amount);
            balance_book[msg.sender] = 0;
        }            
    }
    
    // fallback function, return unexpected money transfer
    receive() external payable {
        (msg.sender).transfer(msg.value);
    }
}
