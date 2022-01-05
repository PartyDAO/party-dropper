// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "./Vm.sol";
import "./MockPartyBid.sol";
import "../PartyDropper.sol";
import "openzeppelin-contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Console.sol";

contract User is ERC1155Holder {
    PartyDropper public dropper;

    constructor(address _dropperAddress) {
        dropper = PartyDropper(_dropperAddress);
    }

    function createEdition(
        address _party,
        string memory _name,
        string memory _imageURI,
        string memory _animationURI,
        string memory _description,
        string memory _artistName
    ) public {
        dropper.createEdition(
            _party,
            _name,
            _imageURI,
            _animationURI,
            _description,
            _artistName
        );
    }

    function mintFromEdition(uint256 editionId) public {
        dropper.mintFromEdition(editionId);
    }
}

contract PartyDropperTest is DSTest {
    Vm vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    PartyDropper partyDropper;
    User user1;
    User user2;

    function setUp() public {
        partyDropper = new PartyDropper();
        user1 = new User(address(partyDropper));
        user2 = new User(address(partyDropper));
    }

    function testSimpleCreateAsOwner() public {
        partyDropper.createEdition(
            address(0),
            "some name",
            "some image",
            "",
            "some description",
            "joey badass"
        );
        (
            address partyAddress,
            string memory name,
            string memory image,
            string memory description,
            string memory animationUri,
            string memory artistName
        ) = partyDropper.editionInfo(1);
        assertEq(partyAddress, address(0));
        assertEq(name, "some name");
        assertEq(image, "some image");
        assertEq(description, "some description");
        assertEq(animationUri, "");
        assertEq(artistName, "joey badass");
        assertEq(partyDropper.editionCreator(1), partyDropper.owner());
    }

    function testCannotCreateEditionAsNonOwner() public {
        try
            user1.createEdition(
                address(0),
                "some name",
                "some image",
                "",
                "some description",
                "joey badass"
            )
        {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "must be allowed creator or owner");
        }
    }

    function testCanCreateEditionAsAddedUser() public {
        partyDropper.setAllowedCreator(address(user1), true);
        user1.createEdition(
            address(0),
            "some user1 name",
            "some image",
            "",
            "some description",
            "joey badass"
        );
        (
            address _partyAddress,
            string memory name,
            string memory _image,
            string memory _description,
            string memory _animationUri,
            string memory _artistName
        ) = partyDropper.editionInfo(1);
        assertEq(name, "some user1 name");
        assertEq(partyDropper.editionCreator(1), address(user1));
    }

    function testCanMintFromEdition() public {
        MockPartyBid mb = new MockPartyBid();
        mb.setContribution(address(user1), 5);

        partyDropper.createEdition(address(mb), "n", "i", "", "d", "x");
        assertEq(partyDropper.totalSupply(1), 0);
        assertEq(partyDropper.balanceOf(address(user1), 1), 0);
        user1.mintFromEdition(1);
        assertEq(partyDropper.totalSupply(1), 1);
        assertEq(partyDropper.balanceOf(address(user1), 1), 1);
    }

    // can't mint twice
    function testCantMintFromEditionTwice() public {
        MockPartyBid mb = new MockPartyBid();
        mb.setContribution(address(user1), 5);

        partyDropper.createEdition(address(mb), "n", "i", "", "d", "x");
        user1.mintFromEdition(1);
        try user1.mintFromEdition(1) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "already minted");
        }
    }

    // can't mint if didnt contribute
    function testCantMintIfDidntContribute() public {
        MockPartyBid mb = new MockPartyBid();
        mb.setContribution(address(user2), 5);

        partyDropper.createEdition(address(mb), "n", "i", "", "d", "x");
        try user1.mintFromEdition(1) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "didn't contribute to PartyBid");
        }
    }

    function testTokenUriWorks() public {
        partyDropper.createEdition(
            address(0),
            "hello world",
            "ar://someimage",
            "",
            "welcoming the world",
            "deployoooor"
        );
        assertEq(
            partyDropper.uri(1),
            "data:application/json;base64,eyJuYW1lIjogImhlbGxvIHdvcmxkIiwgImRlc2NyaXB0aW9uIjogIndlbGNvbWluZyB0aGUgd29ybGQiLCAiaW1hZ2UiOiAiYXI6Ly9zb21laW1hZ2UiLCAiYXR0cmlidXRlcyI6IFsgeyAidHJhaXRfdHlwZSI6ICJEcm9wIE5hbWUiLCAidmFsdWUiOiAiaGVsbG8gd29ybGQiIH0sIHsgInRyYWl0X3R5cGUiOiAiQXJ0aXN0IE5hbWUiLCAidmFsdWUiOiAiZGVwbG95b29vb3IiIH0gXX0="
        );
        partyDropper.createEdition(
            address(0),
            "with video",
            "ar://someimage",
            "ipfs://somevideo",
            "sup video",
            "deployoooor"
        );
        assertEq(
            partyDropper.uri(2),
            "data:application/json;base64,eyJuYW1lIjogIndpdGggdmlkZW8iLCAiZGVzY3JpcHRpb24iOiAic3VwIHZpZGVvIiwgImltYWdlIjogImFyOi8vc29tZWltYWdlIiwgImFuaW1hdGlvbl91cmwiOiAiaXBmczovL3NvbWV2aWRlbyIsICJhdHRyaWJ1dGVzIjogWyB7ICJ0cmFpdF90eXBlIjogIkRyb3AgTmFtZSIsICJ2YWx1ZSI6ICJ3aXRoIHZpZGVvIiB9LCB7ICJ0cmFpdF90eXBlIjogIkFydGlzdCBOYW1lIiwgInZhbHVlIjogImRlcGxveW9vb29yIiB9IF19"
        );
    }

    // can create two editions and minting protection works
    function testCanWorkWithMultipleEditions() public {
        MockPartyBid mb1 = new MockPartyBid();
        mb1.setContribution(address(user1), 5);

        MockPartyBid mb2 = new MockPartyBid();
        mb2.setContribution(address(user2), 5);

        partyDropper.createEdition(
            address(mb1),
            "party1",
            "ar://party1.jpg",
            "",
            "dope party 1",
            "deployoooor"
        );
        partyDropper.createEdition(
            address(mb2),
            "party2",
            "ar://party2.jpg",
            "",
            "dope party 2",
            "deployoooor"
        );

        user1.mintFromEdition(1);
        try user1.mintFromEdition(2) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "didn't contribute to PartyBid");
        }

        user2.mintFromEdition(2);
        try user2.mintFromEdition(1) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "didn't contribute to PartyBid");
        }

        assertEq(
            partyDropper.uri(1),
            "data:application/json;base64,eyJuYW1lIjogInBhcnR5MSIsICJkZXNjcmlwdGlvbiI6ICJkb3BlIHBhcnR5IDEiLCAiaW1hZ2UiOiAiYXI6Ly9wYXJ0eTEuanBnIiwgImF0dHJpYnV0ZXMiOiBbIHsgInRyYWl0X3R5cGUiOiAiRHJvcCBOYW1lIiwgInZhbHVlIjogInBhcnR5MSIgfSwgeyAidHJhaXRfdHlwZSI6ICJBcnRpc3QgTmFtZSIsICJ2YWx1ZSI6ICJkZXBsb3lvb29vciIgfSBdfQ=="
        );
        assertEq(
            partyDropper.uri(2),
            "data:application/json;base64,eyJuYW1lIjogInBhcnR5MiIsICJkZXNjcmlwdGlvbiI6ICJkb3BlIHBhcnR5IDIiLCAiaW1hZ2UiOiAiYXI6Ly9wYXJ0eTIuanBnIiwgImF0dHJpYnV0ZXMiOiBbIHsgInRyYWl0X3R5cGUiOiAiRHJvcCBOYW1lIiwgInZhbHVlIjogInBhcnR5MiIgfSwgeyAidHJhaXRfdHlwZSI6ICJBcnRpc3QgTmFtZSIsICJ2YWx1ZSI6ICJkZXBsb3lvb29vciIgfSBdfQ=="
        );
    }

    // test user can mint multiple items
    function testCanBuildMultipleItems() public {
        MockPartyBid mb1 = new MockPartyBid();
        mb1.setContribution(address(user1), 5);

        MockPartyBid mb2 = new MockPartyBid();
        mb2.setContribution(address(user1), 10);

        partyDropper.createEdition(
            address(mb1),
            "party1",
            "ar://party1.jpg",
            "",
            "dope party 1",
            "deployoooor"
        );
        partyDropper.createEdition(
            address(mb2),
            "party1",
            "ar://party1.jpg",
            "",
            "dope party 1",
            "deployoooor"
        );

        user1.mintFromEdition(1);
        user1.mintFromEdition(2);
        try user1.mintFromEdition(1) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "already minted");
        }
        try user1.mintFromEdition(2) {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "already minted");
        }
    }
}
