# task: handlers/AuctionHandler.lua - style(auction): fix indentation for PriceMatchesPending call
Fix the indentation of the PriceMatchesPending call in AuctionHandler.lua to match the surrounding code

# task: services/SalesService.lua - docs(sales): document ProcessSale transaction handling
Add a comment above the Dukonomics.SalesService.ProcessSale function explaining it processes sale transactions

# task: data/Repository.lua - style(data): trim trailing whitespace in Repository.lua
Trim trailing whitespace from all lines in data/Repository.lua

# task: data/ConfigRepository.lua - docs(config): add comment to ConfigRepository.Get()
Add a comment above the Dukonomics.ConfigRepository.Get function explaining it gets a config value

# task: testing/TestRunner.lua - refactor(testing): remove unused index variable in TEST_MAILS loop
Remove the unused index variable 'i' from the for loop iterating over TEST_MAILS, using '_' instead

# task: UI/MinimapButton.lua - docs(ui/minimap): explain Initialize() purpose
Add a comment above the Dukonomics.UI.MinimapButton.Initialize function explaining it initializes the minimap button

# task: data/MailCache.lua - refactor(data/mailcache): rename mailObj to mail_obj for consistency
Rename the variable 'mailObj' to 'mail_obj' throughout data/MailCache.lua for naming consistency

# task: core/Logger.lua - docs(logger): annotate chat prefix constants
Add a comment above the PREFIX constant explaining it's for chat output prefixes

# task: Commands.lua - docs(commands): add processing note after command parsing
Add a comment after the command parsing line explaining it processes the command

# task: core/Logger.lua - chore(logger): add placeholder for future i18n of prefix
Add a placeholder variable for future internationalization of the logger prefix

# task: UI/MainFrame.xml - docs(ui/mainframe): annotate main UI frame header
Add a comment above the main UI frame explaining it's the main UI frame

# task: services/SalesService.lua - chore(sales): guard init debug behind debug mode flag
Guard the "SalesService initialized" debug log behind a debug mode flag check

# task: Dukonomics.toc - style(toc): normalize IconTexture line format
Normalize the IconTexture line format in Dukonomics.toc

# task: README.md - docs(readme): ensure trailing newline for formatting consistency
Ensure README.md ends with a trailing newline for formatting consistency

# task: handlers/MailHandler.lua - chore(mail): add simple CLOSE_INBOX_ITEM index debug line near handler start
Add a debug line at the start of the OnCloseInboxItem handler to log the mail index

# task: UI/Formatting.lua - fix(formatting): properly format gold amounts with million separators
Fix the gold formatting logic to properly handle million separators (1,500,000g instead of 1500,000g)

# task: core/Logger.lua - feat(logger): add warn() method for non-critical warnings
Add a warn() method to the Logger module for non-critical warnings

# task: core/Logger.lua - fix(logger): add missing error() method used by MinimapButton
Add the missing error() method to the Logger module that is used by MinimapButton

# task: UI/components/SummaryBar.lua - refactor(summary): use shared FormatMoney instead of duplicated local copy
Replace the local FormatMoney function in SummaryBar.lua with calls to the shared Dukonomics.UI.Formatting.FormatMoney

# task: UI/Formatting.lua - fix(formatting): handle negative copper values in FormatMoney
Add handling for negative copper values in the FormatMoney function

# task: UI/Formatting.lua - fix(formatting): guard FormatPostedTime against future timestamps
Add a guard in FormatPostedTime to handle future timestamps gracefully

# task: UI/components/DataTable.lua - feat(ui): add empty state message when no data matches filters
Add an empty state message in DataTable.lua when no transactions match the current filters

# task: Core.lua - feat(core): add version constant for reuse across modules
Add a VERSION constant to the main Dukonomics table for reuse across modules

# task: UI/MainFrame.lua - feat(ui): show version in main frame title bar
Update the main frame title to show the addon version

# task: Commands.lua - feat(commands): add /duk version command to display addon version
Add a /duk version command that displays the addon version

# task: Commands.lua - docs(commands): add version to help output
Add the version command to the help output

# task: Commands.lua - feat(commands): add /duk reset command to restore default config
Add a /duk reset command that restores default configuration

# task: data/Repository.lua - feat(data): add GetPostingCount() utility for quick stats
Add a GetPostingCounts() function to Repository.lua for getting posting statistics

# task: UI/MinimapButton.lua - feat(minimap): show quick stats in minimap tooltip
Update the minimap tooltip to show quick posting statistics

# task: core/Localization.lua - feat(localization): add Spanish translations for common UI labels
Add Spanish translations for common UI labels in Localization.lua

# task: data/Repository.lua - fix(data): guard ClearOldData against nil or zero daysToKeep
Add guards in ClearOldData to handle nil or zero daysToKeep values

# task: data/Repository.lua - feat(data): add GetPurchaseCount() for purchase statistics
Add a GetPurchaseCount() function to Repository.lua

# task: data/Repository.lua - docs(data): annotate POSTING OPERATIONS section header
Add a descriptive comment to the POSTING OPERATIONS section header

# task: data/Repository.lua - docs(data): annotate PURCHASE OPERATIONS section header
Add a descriptive comment to the PURCHASE OPERATIONS section header

# task: data/Repository.lua - docs(data): annotate QUERIES section header
Add a descriptive comment to the QUERIES section header

# task: data/Repository.lua - docs(data): annotate TRANSACTIONS section header
Add a descriptive comment to the TRANSACTIONS section header

# task: data/Repository.lua - docs(data): annotate MAINTENANCE section header
Add a descriptive comment to the MAINTENANCE section header

# task: UI/OptionsPanel.lua - feat(options): add version display in options panel header
Update the options panel header to show the addon version

# task: UI/OptionsPanel.lua - feat(options): add minimap visibility toggle in options panel
Add a minimap visibility toggle checkbox to the options panel

# task: handlers/AuctionHandler.lua - docs(auction): document main event handler functions
Add documentation comments to the main event handler functions in AuctionHandler.lua

# task: handlers/MailHandler.lua - docs(mail): document mail processing functions
Add documentation comments to the mail processing functions in MailHandler.lua

# task: Core.lua - feat(core): add pcall safety wrapper for initialization
Wrap the Dukonomics.Initialize() call in a pcall for safety

# task: Commands.lua - refactor(commands): extract debug-only guard into helper function
Extract the debug mode check into a helper function RequireDebugMode()

# task: data/MailData.lua - style(maildata): align schema field definitions for readability
Align the schema field definitions in MailData.lua for better readability

# task: UI/Config.lua - feat(ui/config): add configurable max visible rows constant
Add a MAX_VISIBLE_ROWS constant to the UI config

# task: UI/Config.lua - feat(ui/config): add color for positive and negative profit
Add profit color definitions to the UI config

# task: UI/Config.lua - docs(ui/config): add header comments for config sections
Add header comments for the COLORS, SIZES, and COLUMNS sections in UI config

# task: core/Localization.lua - feat(localization): add Portuguese translations for core labels
Add Portuguese translations for core UI labels

# task: data/Repository.lua - feat(data): add HasData() check for quick empty-state detection
Add a HasData() function to check if there's any data stored

# task: data/Repository.lua - fix(data): ensure purchases table exists before operations
Ensure the purchases table exists before adding purchases

# task: services/SalesService.lua - docs(sales): document each matching strategy
Add documentation comments for each sales matching strategy

# task: testing/TestRunner.lua - feat(testing): add test counter and pass/fail summary
Add test counting and summary display to the test runner

# task: Dukonomics.toc - chore(toc): add X-Website and X-Category metadata
Add X-Website and X-Category metadata to the TOC file

# task: Core.lua - docs(core): add module dependency loading order comment
Add a comment explaining the module loading order

# task: Commands.lua - feat(commands): add /duk count command for quick stats
Add a /duk count command to display quick statistics

# task: core/Logger.lua - style(logger): use consistent color codes for prefix constants
Update the DEBUG_PREFIX to use consistent color codes

# task: data/MailCache.lua - docs(mailcache): document MailCache public API methods
Add documentation comments to all MailCache public methods

# task: data/MailData.lua - docs(maildata): document MailData public methods
Add documentation comments to MailData public methods

# task: UI/Config.lua - feat(ui/config): add color for deposit column (future use)
Add a DEPOSIT color definition for future use

# task: data/Repository.lua - feat(data): add GetOldestTimestamp() for data range display
Add a GetOldestTimestamp() function for displaying data ranges

# task: testing/TestRunner.lua - refactor(testing): extract source creation into shared helper
Extract the test source creation into a shared helper function

# task: data/ConfigRepository.lua - chore(configrepo): add debug log when loading cached filters
Add a debug log when loading cached filters

# task: UI/Formatting.lua - feat(formatting): add FormatPercentage utility for future profit margins
Add FormatPercentage and FormatCount utility functions

# task: UI/Formatting.lua - docs(formatting): add module description comment
Update the module description comment for Formatting.lua