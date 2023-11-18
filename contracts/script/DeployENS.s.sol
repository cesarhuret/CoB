pragma solidity >=0.8.4;
import {INameWrapper, PublicResolver} from "@ensdomains/ens-contracts/contracts/resolvers/PublicResolver.sol";
import "@ensdomains/ens-contracts/contracts/registry/ENSRegistry.sol";
import "@ensdomains/ens-contracts/contracts/registry/FIFSRegistrar.sol";
import {NameResolver, ReverseRegistrar} from "@ensdomains/ens-contracts/contracts/registry/ReverseRegistrar.sol";
import {Script, console2} from "forge-std/Script.sol";

// Construct a set of test ENS contracts.
contract ENSDeployer is Script {
    bytes32 public constant TLD_LABEL = keccak256("eth");
    bytes32 public constant RESOLVER_LABEL = keccak256("resolver");
    bytes32 public constant REVERSE_REGISTRAR_LABEL = keccak256("reverse");
    bytes32 public constant ADDR_LABEL = keccak256("addr");

    ENSRegistry public ens;
    FIFSRegistrar public fifsRegistrar;
    ReverseRegistrar public reverseRegistrar;

    PublicResolver public publicResolver;

    function namehash(
        bytes32 node,
        bytes32 label
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(node, label));
    }

    function setUp() public {}

    function run() public {
        vm.broadcast();

        ens = new ENSRegistry();
        reverseRegistrar = new ReverseRegistrar(ens);

        publicResolver = new PublicResolver(
            ens,
            INameWrapper(address(0)),
            address(0),
            address(reverseRegistrar)
        );

        // Set up the resolver
        bytes32 resolverNode = namehash(bytes32(0), RESOLVER_LABEL);

        ens.setSubnodeOwner(bytes32(0), RESOLVER_LABEL, address(this));
        ens.setResolver(resolverNode, address(publicResolver));
        publicResolver.setAddr(resolverNode, address(publicResolver));

        // Create a FIFS registrar for the TLD
        fifsRegistrar = new FIFSRegistrar(ens, namehash(bytes32(0), TLD_LABEL));

        ens.setSubnodeOwner(bytes32(0), TLD_LABEL, address(fifsRegistrar));

        // Construct a new reverse registrar and point it at the public resolver

        // Set up the reverse registrar
        ens.setSubnodeOwner(bytes32(0), REVERSE_REGISTRAR_LABEL, address(this));
        ens.setSubnodeOwner(
            namehash(bytes32(0), REVERSE_REGISTRAR_LABEL),
            ADDR_LABEL,
            address(reverseRegistrar)
        );

        console2.logAddress(address(ens));
        console2.logAddress(address(fifsRegistrar));
        console2.logAddress(address(reverseRegistrar));
        console2.logAddress(address(publicResolver));
    }
}
