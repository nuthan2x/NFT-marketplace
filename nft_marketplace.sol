//SPDX-License-Identifier: MIT

pragma solidity >=0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MarketPlace is ReentrancyGuard{
    using Counters for Counters.Counter;
    Counters.Counter public _ItemIds;
    Counters.Counter public _ItemsSold;

    uint public listingPrice = 0.00001 ether;
    address public owner = msg.sender;

    struct Iteminfo{
        uint mapId;
        uint tokenid;
        uint price;
        address Nftcontract;
        address seller;
        address newOwner;
        bool sold;
    }

    event NewItem_Created(
        uint indexed mapId,
        uint indexed tokenid,
        uint price,
        address  seller,
        address  newOwner,
        bool sold);

    mapping(uint => Iteminfo) public Id_to_Iteminfo;

    function getListingPrice() external view returns(uint){
        return listingPrice;
    }

    function create_MarketItem(address Nftcontract,uint _tokenId,uint _price) external payable nonReentrant {
        require(_price >0);
        require(msg.value == listingPrice);
        _ItemIds.increment();
        uint ItemId = _ItemIds.current() ;
        Id_to_Iteminfo[ItemId] = Iteminfo(
            ItemId,
            _tokenId,
            _price,
            Nftcontract,
            msg.sender,
            address(0),
            false
        );

        IERC721(Nftcontract).transferFrom(msg.sender,address(this),_tokenId);
        emit NewItem_Created(ItemId,_tokenId,_price,msg.sender,address(0),false);

    }

    function Sale(address nftcontract,uint _itemId) external payable nonReentrant {
        uint price = Id_to_Iteminfo[_itemId].price;
        uint tokenid = Id_to_Iteminfo[_itemId].tokenid;
        address seller = Id_to_Iteminfo[_itemId].seller;
        
        require(msg.value == price);
        payable(seller).transfer(msg.value);

        IERC721(nftcontract).transferFrom(address(this),msg.sender,tokenid);
        Id_to_Iteminfo[_itemId].sold = true;
        Id_to_Iteminfo[_itemId].newOwner = payable(msg.sender);
        _ItemsSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function Unsold_Items() external view  returns(Iteminfo[] memory){
        uint itemcount = _ItemIds.current();
        uint unsold_itemcount = itemcount - _ItemsSold.current();
        uint unsolditems_index = 0;

        Iteminfo[] memory Unsold_items = new Iteminfo[](unsold_itemcount);

        for(uint i =0; i < itemcount; i++){
            if(Id_to_Iteminfo[i++].newOwner == address(0)){
                Unsold_items[unsolditems_index] = Id_to_Iteminfo[i++];
                unsolditems_index++;
            }
        }

        return Unsold_items;
    }

    function get_myNfts() public view returns (Iteminfo[] memory) {
        uint total_items = _ItemIds.current();
        uint myNfts_itemcount;
        uint myNfts_index;

        Iteminfo[] memory myNfts = new Iteminfo[](myNfts_index);
        for(uint i = 0;i < total_items;i++){
            if(Id_to_Iteminfo[i++].newOwner == msg.sender){
                myNfts_itemcount++;

                myNfts[myNfts_index] = Id_to_Iteminfo[i++];
                myNfts_index++;
            }
        }
        return myNfts;
    }

    function Listed_myNfts() public view returns (Iteminfo[] memory) {
        uint total_items = _ItemIds.current();
        uint myNfts_itemcount;
        uint myNfts_index;

        Iteminfo[] memory myNfts_forSale = new Iteminfo[](myNfts_index);
        for(uint i = 0;i < total_items;i++){
            if(Id_to_Iteminfo[i++].seller == msg.sender){
                myNfts_itemcount++;

                myNfts_forSale[myNfts_index] = Id_to_Iteminfo[i++];
                myNfts_index++;
            }
        }
        return myNfts_forSale;
    }    
}
