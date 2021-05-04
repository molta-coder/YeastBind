// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

 

contract YeastBind {
    address payable public beneficiary;
    uint public size;
    uint public biddingEnd;
    uint public revealEnd;
    bool public ended;    
    
      struct Bid{
        bytes32 hasOfBid;  
        uint deposit;
    }
    
    mapping(address => Bid[]) public bids;
    // Allowed withdrawals of previous bids
    mapping(address => uint) pendingReturns;
    
    address public highestBidder;
    uint public highestBid;
    
    event AuctionEnded(address winner, uint highestBid);
    
    modifier onlyBefore(uint _time)  { require(block.timestamp < _time); _; }
    modifier onlyAfter(uint _time) { require(block.timestamp > _time); _; }
    
    constructor(uint _biddingTime, uint _revealTime, address payable _beneficiary, uint _size){
        beneficiary = _beneficiary;
        size = _size;
        biddingEnd = block.timestamp +_biddingTime;
        revealEnd = biddingEnd + _revealTime;
    }
    
    function registerBid(bytes32 _hasOfBid) public payable onlyBefore(biddingEnd){
        bids[msg.sender].push(Bid({hasOfBid: _hasOfBid, deposit: msg.value}));
    }
    
    function reveal(uint[] memory _price, uint[] memory _quantity, bytes32[] memory _salt) public onlyAfter(biddingEnd) onlyBefore(revealEnd){
        uint length = bids[msg.sender].length;
        require(_price.length == length);
        require(_quantity.length == length);
        require(_salt.length == length);
    
        uint refund;
        for (uint i = 0; i < length; i++){
            Bid storage bidToCheck = bids[msg.sender][i];
            (uint price, uint quantity, bytes32 salt) = (_price[i], _quantity[i], _salt[i]);
            if (bidToCheck.hasOfBid != keccak256(abi.encodePacked(price, quantity, salt))) {
                // Bid was not actually revealed.
                // Do not refund deposit.
                continue;
            }
            refund += bidToCheck.deposit;
            if ( bidToCheck.deposit >= price) {
                if (placeBid(msg.sender, price, quantity))
                    refund -= value;
            }
            bidToCheck.hasOfBid = bytes32(0);
        }
        payable(msg.sender).transfer(refund);
    }
    
    function withdraw() public{
        uint amount = pendingReturns[msg.sender];
        if (amount > 0){
            pendingReturns[msg.sender] = 0;
            payable(msg.sender).transfer(amount);
        }
    }
    
    function auctionEnd() public onlyAfter(revealEnd){
        require (!ended);
        emit AuctionEnded(highestBidder, highestBid);
        ended = true;
        beneficiary.transfer(highestBid);
    }
    
    function placeBid(address bidder, uint price, uint quantity) internal returns (bool success){
        if (value <= highestBid){
            return false;
        }
        if (highestBidder != address(0)){
            pendingReturns[highestBidder] += highestBid;
        }
        highestBid = value;
        highestBidder = bidder;
        return true;
    }
}
