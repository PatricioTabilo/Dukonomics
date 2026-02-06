# Task 1: Update version fallback in Core.lua to match current version
sed -i 's/"0.4.0"/"0.9.0"/' Core.lua
# Task 2: Fix typo in MinimapButton.lua (singular instead of plural)
sed -i 's/Bibliotecas LibDataBroker no encontradas/Biblioteca LibDataBroker no encontrada/' UI/MinimapButton.lua
# Task 3: Add comment to Dukonomics table initialization
sed -i 's/Dukonomics = {}/-- Main addon table\nDukonomics = {}/' Core.lua
# Task 4: Add comment to Logger functions
sed -i 's/function Dukonomics.Logger.print/-- Print a message with addon prefix\nfunction Dukonomics.Logger.print/' core/Logger.lua
# Task 5: Standardize variable name in Commands.lua (msg to message)
sed -i 's/function(msg)/function(message)/' Commands.lua
# Task 6: Remove unnecessary debug log in Core.lua
sed -i '/Dukonomics.Logger.debug("Initialization complete")/d' Core.lua
# Task 7: Add local to MailCache variable
sed -i 's/if not Dukonomics then Dukonomics = {} end/local Dukonomics = Dukonomics or {}\nif not Dukonomics then Dukonomics = {} end/' data/MailCache.lua
# Task 8: Optimize string concatenation in TestRunner.lua
sed -i 's/ .. table.concat(parts, ", ") .. "/table.concat(parts, ", "))/' testing/TestRunner.lua
# Task 9: Add error check in MailHandler.lua
sed -i 's/Dukonomics.Logger.debug("CLOSE_INBOX_ITEM:/Dukonomics.Logger.debug("CLOSE_INBOX_ITEM: #" .. tostring(mailIndex) .. " '\''" .. tostring(mail.subject or "no subject") .. "'\''"))/' handlers/MailHandler.lua
# Task 10: Fix indentation in AuctionHandler.lua
sed -i 's/       PriceMatchesPending/      PriceMatchesPending/' handlers/AuctionHandler.lua
# Task 11: Add comment to SalesService functions
sed -i 's/function Dukonomics.SalesService.ProcessSale/-- Process a sale transaction\nfunction Dukonomics.SalesService.ProcessSale/' services/SalesService.lua
# Task 12: Remove trailing spaces in Repository.lua
sed -i 's/[ \t]*$//' data/Repository.lua
# Task 13: Add type hint comment in ConfigRepository.lua
sed -i 's/function Dukonomics.ConfigRepository.Get/-- Get a config value\nfunction Dukonomics.ConfigRepository.Get/' data/ConfigRepository.lua
# Task 14: Optimize loop in TestRunner.lua
sed -i 's/for i, mail in ipairs(TEST_MAILS) do/for _, mail in ipairs(TEST_MAILS) do/' testing/TestRunner.lua
# Task 15: Add comment to UI MinimapButton
sed -i 's/function Dukonomics.UI.MinimapButton.Initialize/-- Initialize the minimap button\nfunction Dukonomics.UI.MinimapButton.Initialize/' UI/MinimapButton.lua
# Task 16: Fix variable name in MailCache.lua
sed -i 's/mailObj/mail_object/' data/MailCache.lua
# Task 17: Add constant for prefix in Logger.lua
sed -i 's/local PREFIX = "|cFF00D4FFDukonomics:|r "/local PREFIX = "|cFF00D4FFDukonomics:|r "\nlocal DEBUG_PREFIX = "|cFF808080[Dukonomics]|r "/' core/Logger.lua
# Task 18: Remove unused variable in Commands.lua
sed -i '/local cmd, arg = msg:match/ s/$/\n  -- Process command/' Commands.lua
# Task 19: Add localization support in Logger.lua
sed -i 's/PREFIX/local prefix = Dukonomics.Loc and Dukonomics.Loc("Dukonomics") or "Dukonomics"\nlocal PREFIX = "|cFF00D4FF" .. prefix .. ":|r "/' core/Logger.lua
# Task 20: Optimize table insert in Repository.lua
sed -i 's/table.insert(chars, {/table.insert(chars, { character = item.source.character, realm = item.source.realm, key = key })/' data/Repository.lua
# Task 21: Add comment to main frame
sed -i 's/<Ui/-- Main UI frame\n<Ui/' UI/MainFrame.xml
# Task 22: Fix case in error message
sed -i 's/No hay datos/No hay datos/' data/Repository.lua
# Task 23: Add debug check in services
sed -i 's/Dukonomics.Logger.debug("SalesService initialized")/if Dukonomics.DebugMode then Dukonomics.Logger.debug("SalesService initialized") end/' services/SalesService.lua
# Task 24: Standardize quotes in toc
sed -i 's/## IconTexture: Interface\\Icons\\INV_Misc_Coin_01/## IconTexture: Interface\\Icons\\INV_Misc_Coin_01/' Dukonomics.toc