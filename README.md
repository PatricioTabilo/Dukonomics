# Dukonomics

Auction House accounting and tracking addon for World of Warcraft.

## Features (In Development)

- 📊 Track all your AH postings with real-time status updates
- 💰 Record sales, cancellations, and expirations
- 👤 Multi-character support
- 🔍 Filter by status (Active, Sold, Expired, Cancelled)
- ⏱️ Countdown timers for active auctions
- 📈 Statistics and profit tracking

## Installation (Development)

### Using Symlink (Recommended for Development)

```bash
# Create symlink from project to WoW AddOns folder
ln -s /home/duck/Development/Dukonomics \
  "/home/duck/.local/share/Steam/steamapps/compatdata/3159493747/pfx/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/Dukonomics"
```

### Manual Copy

Copy the `Dukonomics` folder to your WoW `Interface/AddOns` directory.

## Usage

- `/dukonomics` or `/duk` - Open main UI (coming soon)
- `/duk debug` - Toggle debug mode

## Development Status

**Phase 1: Foundation** ✅ Completed

- [x] Project structure
- [x] Core initialization
- [x] Data persistence (SavedVariables)
- [x] Event handling system
- [x] Git repository setup
- [x] Symlink to WoW

**Phase 2: Backend** 🔄 Next

- [ ] Auction tracking events
- [ ] Mail inbox monitoring
- [ ] Status management

**Phase 3: UI** 📋 Planned

- [ ] Main frame design (Peterodox-inspired)
- [ ] Data table view
- [ ] Filters
- [ ] Statistics panel

**Phase 4: Polish** 📋 Planned

- [ ] Testing
- [ ] Documentation
- [ ] Screenshots

## Technical Details

- **Interface Version:** 110002 (The War Within)
- **Saved Variables:** `DUKONOMICS_DATA`
- **Events Used:**
  - `AUCTION_HOUSE_AUCTION_CREATED` - Capture auctionID when posting
  - `AUCTION_HOUSE_PURCHASE_COMPLETED` - Detect sales
  - `AUCTION_CANCELED` - Detect cancellations
  - `OWNED_AUCTIONS_UPDATED` - Sync auction status

## Design Philosophy

**Focus:** Pure accounting and tracking - no active tools or market manipulation

**Inspiration:** Clean, elegant UI following patterns from [Peterodox's addons](https://www.curseforge.com/members/peterodox/projects)

## License

MIT License - See LICENSE file

## Author

Duck - Making gold tracking beautiful since 2026
