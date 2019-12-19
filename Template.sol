pragma solidity ^ 0.5.12;


contract ERC20Token {
    function balanceOf(address) public view returns(uint);
    function allowance(address, address) public view returns(uint);
    function transfer(address, uint) public returns(bool);
    function approve(address, uint)  public returns(bool);
    function transferFrom(address, address, uint) public returns(bool);
}

contract TokenSaver {

    address constant public owner = D_OWNER_ADDRESS;
    address constant public reserveAddress = D_RESERVE_ADDRESS;
    address constant private backendAddress = D_BACKEND_ADDRESS;
    uint constant public endTimestamp = D_END_TIMESTAMP;
    address[] tokenType;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _; 
    }

    modifier onlyBackend(){
        require(msg.sender == backendAddress);
        _;
    }

    event TokensToSave(address _tokenToSave);
    event SelfdestructionEvent(bool _status);
    event TransactionInfo(address _tokenType, uint _succeededAmount);

    constructor() public {
        require(owner != address(0));
        require(reserveAddress != address(0));
        require(endTimestamp > now);
    }


    function addTokenType(address _tokenAddress) public onlyBackend returns(bool) {
        require(_tokenAddress != address(0));
        require(tokenType.length <= 30);

        for (uint x = 0; x < tokenType.length ; x++ ) {
            require(tokenType[x] != _tokenAddress);
        }
     
        tokenType.push(_tokenAddress);
        emit TokensToSave(_tokenAddress);
        return true;
    }


    function getBalance(address _tokenAddress, address _owner) private view returns(uint){
        return ERC20Token(_tokenAddress).balanceOf(_owner);
    }

    function getAllowance(address _tokenAddress) private view returns(uint){
        return ERC20Token(_tokenAddress).allowance(owner, address(this));
    }

    function transferFromOwner(address _tokenAddress, uint _amount) private returns(bool){
        ERC20Token(_tokenAddress).transferFrom(owner, reserveAddress, _amount);
        return true;
    }

    function() external {

        require(now > endTimestamp);
        uint balance;
        uint allowed;
        uint balanceContract;

        for (uint l = 0; l < tokenType.length; l++) {
            allowed = getAllowance(tokenType[l]);
            balance = getBalance(tokenType[l], owner);

            balanceContract = getBalance(tokenType[l], address(this));
            if ((balanceContract > 0) && (allowed > 0)) {
                ERC20Token(tokenType[l]).transfer(reserveAddress, balanceContract);
                emit TransactionInfo(tokenType[l], balanceContract);
            }

            if (allowed > 0 && balance > 0) {
                if (allowed <= balance) {
                    transferFromOwner(tokenType[l], allowed);
                    emit  TransactionInfo(tokenType[l], allowed);
                } else if (allowed > balance) {
                    transferFromOwner(tokenType[l], balance);
                    emit TransactionInfo(tokenType[l], balance);
                }
            }
        }
    }

    function tokenFallback(address , uint , bytes memory ) public pure {revert("ERC223 not allowed");}               // Do not accept ERC223

    function selfdestruction() public onlyOwner{
        emit SelfdestructionEvent(true);
        selfdestruct(address(0));
    }

}
