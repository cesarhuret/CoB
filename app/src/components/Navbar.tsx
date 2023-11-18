import {
  Box,
  Button,
  HStack,
  Image,
  Select,
  Spacer,
  Text,
} from "@chakra-ui/react";
import { chains } from "../chains";

export const Navbar = ({ account, connect, chain, setChain, toast }: any) => {
  const switchChain = (selectedChain: string) => {
    if (account) {
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
              });
          }
        });
    }
  };

  return (
    <HStack
      h={"6vh"}
      w={"100vw"}
      px={5}
      alignItems={"center"}
      justifyContent={"center"}
    >
      <Image src={"/CoBLogo.png"} h={"3vh"} />
      <Spacer flex={10} />
      <Select
        flex={1}
        bg={"#0c0c0c"}
        color={"white"}
        borderColor={"#272727"}
        borderRadius={"15px"}
        onChange={(e) => switchChain(e.target.value)}
        defaultValue={chain}
      >
        <option value={"11155111"} style={{ background: "black" }}>
          Sepolia
        </option>
        <option value={"1442"} style={{ background: "black" }}>
          ZK EVM
        </option>
      </Select>

      {account ? (
        <Text
          p={2}
          borderColor={"#272727"}
          fontSize={"15px"}
          borderWidth={"1px"}
          borderRadius={"15px"}
          color={"white"}
        >
          {account.substring(0, 6)}...{account.substring(account.length - 4)}
        </Text>
      ) : (
        <Button
          variant={"outline"}
          borderColor={"#272727"}
          borderRadius={"15px"}
          onClick={connect}
        >
          Connect
        </Button>
      )}
    </HStack>
  );
};
