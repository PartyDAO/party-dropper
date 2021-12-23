// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "./Vm.sol";
import "../PartyDropper.sol";

contract User {
    PartyDropper public dropper;

    constructor(address _dropperAddress) {
        dropper = PartyDropper(_dropperAddress);
    }

    function createEdition(
        address _party,
        string memory _name,
        string memory _imageURI,
        string memory _description
    ) public {
        dropper.createEdition(_party, _name, _imageURI, _description);
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

    function testSimpleCreate() public {
        partyDropper.createEdition(
            address(0),
            "some name",
            "some image",
            "some description"
        );
        (
            address partyAddress,
            string memory name,
            string memory image,
            string memory description
        ) = partyDropper.editionInfo(1);
        assertEq(partyAddress, address(0));
        assertEq(name, "some name");
        assertEq(image, "some image");
        assertEq(description, "some description");
        assertEq(partyDropper.editionCreator(1), partyDropper.owner());
    }

    function testCannotMintAsNonOwner() public {
        try
            user1.createEdition(
                address(0),
                "some name",
                "some image",
                "some description"
            )
        {
            fail();
        } catch Error(string memory error) {
            assertEq(error, "must be allowed creator or owner");
        }
    }

    function testCanMintAsAddedUser() public {
        partyDropper.setAllowedCreator(address(user1), true);
        user1.createEdition(
            address(0),
            "some user1 name",
            "some image",
            "some description"
        );
        (
            address _partyAddress,
            string memory name,
            string memory _image,
            string memory _description
        ) = partyDropper.editionInfo(1);
        assertEq(name, "some user1 name");
        assertEq(partyDropper.editionCreator(1), address(user1));
    }
}
