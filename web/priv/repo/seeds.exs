# Script for populating the development database with representative data.
#
# Reset and seed from the web directory with:
#
#     mix ecto.reset
#
# Or seed an already-reset database with:
#
#     mix run priv/repo/seeds.exs

Memba.DevSeeds.run()
Memba.DevSeeds.deliver_representative_emails()
