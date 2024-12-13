//SPDX-License-Identifier:MIT
pragma solidity ^0.8.2;
import"./IERC20.sol";
contract crowFund{
    event Launch(
    uint id,
    address indexed creator,
    uint goal,
    uint32 startAt,
    uint32 endAt
    );
    event Cancel(uint Id);
    event Pledge(uint indexed Id,address indexed sender,uint amount);
    event unPledge(uint indexed Id,address indexed sender,uint amount);
    event Claim(uint Id);
    struct Campaign{
        address creator;
        uint goal;
        uint pledge;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
    IERC20 public immutable token; 
    uint public count;
    mapping(uint=>Campaign) public campaigns;
    mapping(uint=>mapping(address=>uint)) public pledgeAmount;
    constructor(address _token){
        token=IERC20(_token);
   
    }
    function launch(
        uint _goal,
        uint32 _startAt,
        uint32 _endAt
    )external {
        require(_startAt>block.timestamp,"start at < now");
        require(_endAt>_startAt,"end at < start at");
        require(_endAt<block.timestamp + 90 days,"over time");
        count+=1;
        campaign[count]=Campaign({
            creator:msg.sender,
            goal:_goal,
            pledge:0,
            startAt:_startAt,
            endAt:_endAt,
            claimed:false
        });
        emit Launch(count,msg.sender,_goal,_startAt,_endAt);
    } 

    function cancel(uint _id) external{
        Campaign memory campaign=campaigns[_id];
        require(msg.sender==campaign.creator,"not creator");
        require(block.timestamp<_startAt,"alreay begin");
        delete campaign[_id];
        emit Cancel(_id);

    }
    function pledge(uint _id,uint amount) external{
        Campaign storage campaign=campaigns[_id];
        require(block.timestamp>campaign.startAt,"not start");
        require(block.timestamp<campaign.endAt,"ended");
        campaign.pledge+=_amount;
        pledgeAmount[_id][msg.sender]+=amount;
        token.transferFrom(msg.sender,address(this),_amount);
        emit Pledge(_id,msg.sender,amount);
    }
     function unpledge(uint _id,uint amount) external{
        Campaign storage campaign=campaigns[_id];
        require(block.timestamp<campaign.endAt,"ended");
        require(amount<=campaign.pledge,"no money");
        campaign.pledge-=_amount;
        pledgeAmount[_id][msg.sender]-=amount;
        token.transfer(msg.sender,_amount);
        emit unPledge(_id,msg.sender,amount);
        
    }
    function claim(uint _id) external{
        Campaign storage campaign=campaigns[_id];
        require(msg.sender==campaign.creator,"not creator");
        require(block.timestamp > campaign.endAt,"not ended");
        require(campaign.pledge>=campaign.goal,"not enough");
        require(!campaign.claimed,"claimed");
        campaign.claimed=true;
        token.transfer(msg.sender,campaign.pledge);
        emit Claim(_id);
    }
     function refund(uint _id) external{
        Campaign storage campaign=campaigns[_id];
        require(block.timestamp > campaign.endAt,"not ended");
        require(campaign.pledge<campaign.goal,"enough");
        uint bal=pledgeAmount[_id][msg.sender];
        pledgeAmount[_id][msg.sender]=0;
        token.transfer(msg.sender,bal);
    }
}