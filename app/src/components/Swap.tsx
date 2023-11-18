import { useState, useEffect } from "react";
import {
  Box,
  Button,
  FormControl,
  FormLabel,
  HStack,
  Heading,
  Input,
  Select,
  Stack,
  Text,
  VStack,
} from "@chakra-ui/react";
import { ethers } from "ethers";
import { chains, deployments } from "../chains";

export const Swap = ({ chain, sourceDeployments }: any) => {
  const provider = new ethers.providers.Web3Provider(window.ethereum);

  console.log(chain);

  const destinationChain: any = Object.values(chains).find(
    (c: any) => c.chainId != chain.chainId
  );
  const destinationDeployments: any =
    deployments[parseInt(destinationChain.chainId, 16).toString()];
  const destinationProvider = new ethers.providers.JsonRpcProvider(
    destinationChain.rpcUrls[0]
  );

  const [selectedToken1, setSelectedToken1] = useState<string>("");
  const [token1, setToken1] = useState(0);
  const [token1Balance, setToken1Balance] = useState("");
  const [selectedToken2, setSelectedToken2] = useState<string>("");
  const [token2, setToken2] = useState(0);
  const [token2Balance, setToken2Balance] = useState("");

  const [signer, setSigner] = useState<any>();

  useEffect(() => {
    const getBalance = async () => {
      const abi = [
        "function balanceOf(address account) external view returns (uint256)",
        "function decimals() external view returns (uint8)",
      ];

      const token1 = new ethers.Contract(
        sourceDeployments[selectedToken1],
        abi,
        provider
      );
      const token2 = new ethers.Contract(
        destinationDeployments[selectedToken2],
        abi,
        destinationProvider
      );
      await provider.send("eth_requestAccounts", []);
      const signer = provider.getSigner();
      const address = await signer.getAddress();
      setSigner(signer);
      setToken1Balance(
        ethers.utils.formatUnits(
          await token1.balanceOf(address),
          await token1.decimals()
        )
      );
      setToken2Balance(
        ethers.utils.formatUnits(
          await token2.balanceOf(address),
          await token2.decimals()
        )
      );
    };

    if (selectedToken1 && selectedToken2) getBalance();
  }, [sourceDeployments, selectedToken1, destinationChain]);

  const estimateOutput = async () => {};

  const swap = () => {};

  console.log(token1);

  return (
    <Box
      p={3}
      w={{ base: "95vw", md: "60vw", lg: "475px" }}
      borderWidth={"0.1em"}
      borderColor={"#171717"}
      borderRadius={"25px"}
      background={"#0c0c0c"}
      boxShadow={"-50px 50px 63px #050505,50px -50px 63px #131313"}
    >
      <Stack spacing={2}>
        <Heading p={2} size={"sm"}>
          Swap
        </Heading>
        <FormControl
          id="token1"
          borderWidth={"0.1em"}
          borderRadius={"xl"}
          borderColor={"#171717"}
          p={4}
        >
          <FormLabel fontSize={"16px"} fontWeight={"semibold"}>
            {chain.chainName}
          </FormLabel>
          <HStack alignItems={"end"}>
            <Input
              size={"lg"}
              height={"3rem"}
              variant={"unstyled"}
              type="text"
              value={token1}
              onChange={(e) => setToken1(parseFloat(e.target.value) || 0)}
              flex={3}
              color={"#b0b0b0"}
            />
            <VStack>
              <Select
                borderColor={"#171717"}
                flex={1}
                value={selectedToken1}
                onChange={(e) => {
                  setSelectedToken1(e.target.value);
                  setSelectedToken2(e.target.value == "usdc" ? "eth" : "usdc");
                }}
              >
                <option style={{ background: "#0c0c0c" }} value={"eth"}>
                  ETH
                </option>
                <option style={{ background: "#0c0c0c" }} value={"usdc"}>
                  USDC
                </option>
              </Select>
              <Text fontSize={"12px"}>Max: {token1Balance}</Text>
            </VStack>
          </HStack>
        </FormControl>
        <FormControl
          id="token1"
          borderWidth={"0.1em"}
          borderRadius={"15px"}
          borderColor={"#171717"}
          p={4}
        >
          <FormLabel fontSize={"16px"} fontWeight={"semibold"}>
            {destinationChain.chainName}
          </FormLabel>
          <HStack>
            <Input
              size={"15px"}
              height={"3rem"}
              variant={"unstyled"}
              type="text"
              value={token2}
              flex={3}
              isReadOnly
              color={"#b0b0b0"}
            />
            <VStack>
              <Select
                borderColor={"#171717"}
                flex={1}
                value={selectedToken2}
                onChange={(e) => {
                  setSelectedToken2(e.target.value);
                  setSelectedToken1(e.target.value == "usdc" ? "eth" : "usdc");
                }}
              >
                <option style={{ background: "#0c0c0c" }} value={"eth"}>
                  ETH
                </option>
                <option style={{ background: "#0c0c0c" }} value={"usdc"}>
                  USDC
                </option>
              </Select>
              <Text fontSize={"12px"}>Max: {token2Balance}</Text>
            </VStack>
          </HStack>
        </FormControl>
        <Button
          size={"lg"}
          borderRadius={"15px"}
          variant={"outline"}
          borderColor={"#171717"}
          height={"3.5rem"}
          onClick={swap}
          fontWeight={"medium"}
          isDisabled={token1 == 0 || token1 > parseFloat(token1Balance)}
        >
          Swap
        </Button>
      </Stack>
    </Box>
  );
};
