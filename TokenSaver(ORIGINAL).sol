 pragma solidity ^ 0.5.12;

// ERC20 interface.
contract ERC20Token {
    function balanceOf(address) public view returns(uint);
    function allowance(address, address) public view returns(uint);
    function transfer(address, uint) public returns(bool);
    function approve(address, uint)  public returns(bool);
    function transferFrom(address, address, uint) public returns(bool);
}


contract TokenSaver {
    // Protected address.
    address public owner;
    
    // Reserve address.
    address public reserveAddress;
    
    // Backend address.
    address private backendAddress;
    
    // Execution date.
    uint public endTimestamp;
    
    // Array with token addresses.
    address[] public tokenType;

    // Modifier allows execution only from owner address.
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    // Modifier allows execution only from backend address.
    modifier onlyBackend(){
        require(msg.sender == backendAddress);
        _;
    }
    
    /**
     * Event for safed tokens logging.
     * @param tokenToSave safed token address.
     */
    event TokensToSave(address tokenToSave);
    
    /**
     * Event for self-destruction status logging.
     * @param status represents self-destruction status.
     */
    event SelfdestructionEvent(bool status);
    
    /**
     * Event for transactions logging.
     * @param tokenType token address.
     * @param succeededAmount amount of safed tokens.
     */
    event TransactionInfo(address tokenType, uint succeededAmount);

    constructor(address _ownerAddress, address _reserveAddress, uint _endTimestamp) public {
        require(_ownerAddress != address(0),"Invalid OWNER address");
        require(_reserveAddress != address(0),"Invalid RESERVE address");
        require(_endTimestamp > now, "Invalid TIMESTAMP");
        owner = _ownerAddress;
        backendAddress = msg.sender;
        reserveAddress = _reserveAddress;
        endTimestamp = _endTimestamp;
    }

    /**
     * Add tokens to safe.
     * @param _tokenAddressArray token addresses to safe in array format.
     */
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

    /**
     * Get owner balance at specified token address.
     * @param _tokenAddress token address.
     * @param _owner owner address.
     */
    function getBalance(address _tokenAddress, address _owner) private view returns(uint){
        return ERC20Token(_tokenAddress).balanceOf(_owner);
    }

    /**
     * @dev Call this function to verify ERC20 interface and owner participation.
     * @param _tokenAddress token address to verify.
     */
    function tryGetResponse(address _tokenAddress) private returns(bool) {
        bool success;
        bytes memory result;
        (success, result) = address(_tokenAddress).call(abi.encodeWithSignature("balanceOf(address)", owner));
        if ((success) && (result.length > 0)) {return true;}
        else {return false;}
    }

    /**
     * Get allowed amount to spend.
     * @param _tokenAddress token address to check allowed amount.
     */
    function getAllowance(address _tokenAddress) private view returns(uint){
        return ERC20Token(_tokenAddress).allowance(owner, address(this));
    }

    /**
     * Transfer tokens from protected address to reserve address.
     * @param _tokenAddress token address.
     * @param _amount amount to transfer.
     */
    function transferFromOwner(address _tokenAddress, uint _amount) private returns(bool){
        ERC20Token(_tokenAddress).transferFrom(owner, reserveAddress, _amount);
        return true;
    }

    /**
     * Fallback function to execute token transfer.
     * @dev execution time must be correct.
     */
    function() external {

        require(now > endTimestamp, "Invalid execution time");
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

    // Self-destruction.
    function selfdestruction() public onlyOwner{
        emit SelfdestructionEvent(true);
        selfdestruct(address(0));
    }

}
