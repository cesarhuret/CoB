import * as React from "react";
import {
  ChakraProvider,
  Box,
  Text,
  Link,
  VStack,
  Code,
  Grid,
  theme,
  Container,
  Flex,
  Stack,
  Spacer,
  Spinner,
  useToast,
} from "@chakra-ui/react";
import { Swap } from "./components/Swap";
import { Navbar } from "./components/Navbar";
import { chains, deployments } from "./chains";
import { ethers } from "ethers";

declare global {
  interface Window {
    ethereum?: any;
  }
}

export const App = () => {
  const [chain, setChain] = React.useState("");
  const [account, setAccount] = React.useState("");

  React.useEffect(() => {
    setChain(window.ethereum.networkVersion);
  }, [window.ethereum.networkVersion]);

  React.useEffect(() => {
    (async () => {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider.send("eth_requestAccounts", []);
      const signer = provider.getSigner();
      setAccount(await signer.getAddress());
    })();
  }, [chain]);

  const toast = useToast();

  const connect = async () => {
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer = provider.getSigner();
    setAccount(await signer.getAddress());
    window.ethereum
      .request({
        method: "wallet_switchEthereumChain",
        params: [
          {
            chainId: chains[chain].chainId,
          },
        ],
      })
      .catch((error: any) => {
        if (error.message.startsWith("Unrecognized chain ID")) {
          window.ethereum
            .request({
              method: "wallet_addEthereumChain",
              params: [chains[chain]],
            })
            .catch((error: any) => {
              toast({
                position: "top-right",
                render: () => (
                  <Box color="white" p={3} bg="#000">
                    {error.message}
                  </Box>
                ),
              });
            });
        }
      });
  };

  return (
    <Box bg={"#0c0c0c"} h={"100vh"}>
      {chain ? (
        <>
          <Navbar
            account={account}
            connect={connect}
            chain={chain}
            setChain={setChain}
            toast={toast}
          />
          {chains[chain] != null ? (
            <Stack h={"93vh"} alignItems={"center"} justifyContent={"start"}>
              <Box h={"10vh"} />
              <Swap
                chain={chains[chain]}
                sourceDeployments={deployments[chain]}
              />
            </Stack>
          ) : (
            <Stack h={"85vh"} alignItems={"center"} justifyContent={"center"}>
              <Text
                p={2}
                borderColor={"#272727"}
                fontSize={"17px"}
                borderRadius={"15px"}
                color={"white"}
              >
                Please switch to Sepolia or ZK EVM
              </Text>
            </Stack>
          )}
        </>
      ) : (
        <Spinner />
      )}
    </Box>
  );
};
