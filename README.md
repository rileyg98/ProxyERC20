# ProxyERC20
 
Turns out, nobody thinks of everything when they code. People are dumb sometimes and send your contracts ERC20 tokens you didn't expect.

This lets you perform proxied transfer or Uniswap V2 router sells on these tokens. It also provides a WETH->ETH unwrapper and a raw ETH withdrawal feature. 

To use it (as a copy/paste solidity dev):
1. Copy and paste the file into yours. 
2. Add "is ProxyERC20" to the end of your contract line - you probably have Context and Ownable there so put ", ProxyERC20" in that case. 
3. Edit the "TODO: Set" line from address(0) to address(0x...) where 0x... is the ERC20 controller address. 
4. YOU MUST TRUST THE ERC20 CONTROLLER ADDRESS. It can perform privileged actions on your contract, even after ownership is renounced. 

If you're not a copy/paste dev, congratulations. You should be able to work out what to do from above. 


To use it, you need to provide one extra function to the raw calls - you will need to provide the address of the token you wish to perform your actions on. This supports ERC20-compliant tokens. You can use Etherscan or whatever to make these calls if you've uploaded your contract code as it should come into your contract ABI. 
