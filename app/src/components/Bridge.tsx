import { useState, useEffect } from "react";
import {
  AbsoluteCenter,
  Box,
  Button,
  FormControl,
  FormLabel,
  HStack,
  Heading,
  Image,
  Input,
  Select,
  Stack,
  Text,
  VStack,
  keyframes,
} from "@chakra-ui/react";
import { ethers } from "ethers";
import { chains, deployments } from "../chains";
import cobABI from "../abis/cobweb.json";
import { motion } from "framer-motion";

export const Bridge = ({ chain, setChain, toast, sourceDeployments }: any) => {
  const provider = new ethers.providers.Web3Provider(window.ethereum);

  const animationKeyframes = keyframes`
  0% { transform: scale(1) rotateX(0); border-radius: 20%; }
  100% { transform: scale(1) rotateX(360deg); border-radius: 20%; }
`;

  const animation = `${animationKeyframes} 1.7s ease-in-out infinite`;

  const destinationChain: any = Object.values(chains).find(
    (c: any) => c.chainId != chain.chainId
  );
  const destinationDeployments: any =
    deployments[parseInt(destinationChain.chainId, 16).toString()];
  const destinationProvider = new ethers.providers.JsonRpcProvider(
    destinationChain.rpcUrls[0]
  );

  const [selectedToken1, setSelectedToken1] = useState<string>("usdc");
  const [token1, setToken1] = useState(0);
  const [token1Balance, setToken1Balance] = useState("");
  const [selectedToken2, setSelectedToken2] = useState<string>("eth");
  const [token2, setToken2] = useState(0);
  const [token2Balance, setToken2Balance] = useState("");

  const [spin, setSpin] = useState(false);

  const [signer, setSigner] = useState<any>();

  const switchChain = (selectedChain: string) => {
    setSpin(true);
    window.ethereum
      .request({
        method: "wallet_switchEthereumChain",
        params: [
          {
            chainId: chains[selectedChain].chainId,
          },
        ],
      })
      .then(() => {
        setChain(selectedChain);
        setSpin(false);
      })
      .catch((error: any) => {
        if (error.code == 4902) {
          window.ethereum
            .request({
              method: "wallet_addEthereumChain",
              params: [chains[selectedChain]],
            })
            .catch((error: any) => {
              toast({
                position: "top-right",
                render: () => (
                  <Box color="white" p={3} bg="#000" borderRadius={"lg"}>
                    {error.message}
                  </Box>
                ),
              });
              setSpin(false);
            });
        }
        setSpin(false);
      });
  };

  useEffect(() => {
    const getBalance = async () => {
      const abi = [
        "function balanceOf(address account) external view returns (uint256)",
        "function decimals() external view returns (uint8)",
      ];

      console.log(selectedToken1);
      console.log(sourceDeployments[selectedToken1]);

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
  }, [sourceDeployments, selectedToken1, selectedToken2, destinationChain]);

  const estimateOutput = async () => {};

  const swap = async () => {
    const bridge = new ethers.Contract(
      deployments["bridge"],
      cobABI.abi,
      signer
    );

    const amount = ethers.utils.parseUnits(token1.toString(), 18);
    const deadline = Math.floor(Date.now() / 1000) + 60 * 20;

    const tx = await bridge.bridge(
      // uint256 amountIn,
      // address fromToken,
      // address toToken,
      // uint32 fromChain,
      // uint32 toChain,
      // uint256 deadline,
      // uint256 maxSlippage
      amount,
      sourceDeployments[selectedToken1],
      destinationDeployments[selectedToken2],
      chain.chainIdNumber,
      destinationChain.chainIdNumber,
      deadline,
      0.05
    );
  };

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
        <AbsoluteCenter zIndex={1}>
          <Box
            borderRadius={"lg"}
            borderColor={"#272727"}
            borderWidth={"1px"}
            bg={"#0c0c0c"}
            px={1}
            py={2}
            _hover={{ bgColor: "#1a1a1a" }}
          >
            <Button
              as={motion.div}
              animation={spin ? animation : ""}
              transition="0.5s linear"
              variant={"ghost"}
              _hover={{ bgColor: "transparent" }}
              size={"lg"}
              onClick={() => switchChain(destinationChain.chainIdNumber)}
            >
              <Image src={"/bridge.svg"} h={"0.9rem"} />
            </Button>
          </Box>
        </AbsoluteCenter>
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
          Bridge
        </Button>
      </Stack>
    </Box>
  );
};
