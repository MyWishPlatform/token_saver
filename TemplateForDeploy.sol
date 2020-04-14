 pragma solidity ^ 0.5.12;

interface ERC20Token {
    function balanceOf(address) external view returns(uint);
    function allowance(address, address) external view returns(uint);
    function transfer(address, uint) external returns(bool);
    function approve(address, uint)  external returns(bool);
    function transferFrom(address, address, uint) external returns(bool);
}

contract TokenSaver {

    address constant public owner = D_OWNER_ADDRESS;
    address constant public reserveAddress = D_RESERVE_ADDRESS;
    address constant private backendAddress = D_BACKEND_ADDRESS;
    uint constant public endTimestamp = D_END_TIMESTAMP;
    address constant public oracleAddress = D_ORACLE_ADDRESS;
    bool constant public oracleEnabled = D_ORACLE_ENABLE;

    address[] public tokenType;

    function msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    modifier onlyOwner(){
        require(msgSender() == owner);
        _;
    }
    
    modifier onlyBackend(){
        require(msgSender() == backendAddress);
        _;
    }
    
    event TokensToSave(address tokenToSave);
    event SelfdestructionEvent(bool status);
    event TransactionInfo(address tokenType, uint succeededAmount);

    constructor() public {
        require(owner != address(0),"Invalid OWNER address");
        require(reserveAddress != address(0),"Invalid RESERVE address");
        require(oracleAddress != address(0),"Invalid ORACLE address");
        require(endTimestamp > now, "Invalid TIMESTAMP");
    }

    function addTokenType(address[] memory _tokenAddressArray) public onlyBackend returns(bool) {
        require(_tokenAddressArray[0] != address(0), "Invalid address");
        for (uint x = 0; x < _tokenAddressArray.length ; x++ ) {
            for (uint z = 0; z < tokenType.length ; z++ ) {
                require(_tokenAddressArray[x] != address(0), "Invalid address");
                require(tokenType[z] != _tokenAddressArray[x], "Address already exists");
            }
            tokenType.push(_tokenAddressArray[x]);
            emit TokensToSave(_tokenAddressArray[x]);
        }

        require(tokenType.length <= 30, "Max 30 types allowed");
        return true;
    }

    function getBalance(address _tokenAddress, address _owner) private view returns(uint){
        return ERC20Token(_tokenAddress).balanceOf(_owner);
    }

    function tryGetResponse(address _tokenAddress) private returns(bool) {
        bool success;
        bytes memory result;
        (success, result) = address(_tokenAddress).call(abi.encodeWithSignature("balanceOf(address)", owner));
        if ((success) && (result.length > 0)) {return true;}
        else {return false;}
    }

    function getAllowance(address _tokenAddress) private view returns(uint){
        return ERC20Token(_tokenAddress).allowance(owner, address(this));
    }

    function transferFromOwner(address _tokenAddress, uint _amount) private returns(bool){
        ERC20Token(_tokenAddress).transferFrom(owner, reserveAddress, _amount);
        return true;
    }

    function() external {
        require((!oracleEnabled && now > endTimestamp && msgSender() == backendAddress) || (oracleEnabled && msgSender() == oracleAddress), "Invalid verify unlock");
        uint balance;
        uint allowed;
        uint balanceContract;

        for (uint l = 0; l < tokenType.length; l++) {
            bool success;
            success = tryGetResponse(tokenType[l]);

            if (success) {
                allowed = getAllowance(tokenType[l]);
                balance = getBalance(tokenType[l], owner);
                balanceContract = getBalance(tokenType[l], address(this));

                if ((balanceContract != 0)) {
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
    }

    function selfdestruction() public onlyOwner{
        emit SelfdestructionEvent(true);
        selfdestruct(address(0));
    }

}
