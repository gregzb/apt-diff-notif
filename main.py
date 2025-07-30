import cloudscraper
from bs4 import BeautifulSoup
import time
import random
import os
import apprise
import sys

with open("credentials", "r") as f:
    credentials = f.read().strip().splitlines()
    if len(credentials) == 2:
        user_key, app_token = credentials
    else:
        print("Error: Invalid credentials format in 'credentials' file")


def send_pushover_notification(found_units, prev_found_units, instance_name):
    """Send a Pushover notification about apartment changes."""
    try:
        # You'll need to set these environment variables:
        # PUSHOVER_USER_KEY and PUSHOVER_APP_TOKEN
        # user_key = os.getenv("PUSHOVER_USER_KEY")
        # app_token = os.getenv("PUSHOVER_APP_TOKEN")

        if not user_key or not app_token:
            print("Warning: Pushover credentials not found in environment variables")
            return

        # Create Apprise instance
        apobj = apprise.Apprise()

        # Add Pushover service
        # Format: pover://user@token
        pushover_url = f"pover://{user_key}@{app_token}"
        apobj.add(pushover_url)

        # Format the message with diff
        message = "🏠 Apartment changes detected!\n\n"
        prev_set = set(prev_found_units)
        current_set = set(found_units)

        # New units (in current but not in previous)
        new_units = sorted(current_set - prev_set)
        if new_units:
            message += "➕ Added:\n"
            for unit in new_units:
                bedroom_type, price, sqft, availability = unit
                message += f"•{bedroom_type}|{price}|{sqft}|{availability}\n"

        # Removed units (in previous but not in current)
        removed_units = sorted(prev_set - current_set)
        if removed_units:
            message += "➖ Removed:\n"
            for unit in removed_units:
                bedroom_type, price, sqft, availability = unit
                message += f"•{bedroom_type}|{price}|{sqft}|{availability}\n"

        message = message[:1024]

        # # Show current units
        # message += "Current units:\n"
        # for i, (bedroom_type, price, sqft, availability) in enumerate(found_units, 1):
        #     message += f"  {i}: {bedroom_type} | {price} | {sqft} | {availability}\n"

        # Send notification
        apobj.notify(body=message, title=f"{instance_name} - Changes Detected")
        print("Pushover notification sent successfully")

    except Exception as e:
        print(f"Error sending Pushover notification: {e}")


def extract_unit_info(unit):
    """Extract pricing, square footage, and availability from a unit element."""
    info = {}

    # Extract pricing
    pricing_span = unit.find("span", class_="pricing")
    if pricing_span:
        info["price"] = pricing_span.get_text(strip=True)

    # Extract square footage
    for span in unit.find_all("span"):
        text = span.get_text(strip=True)
        if "sq.ft." in text:
            info["square_feet"] = text
            break

    # Extract availability
    for p in unit.find_all("p"):
        text = p.get_text(strip=True)
        if text.startswith("Available"):
            info["availability"] = text
            break

    return info


def extract_info_from_page_content(content):
    soup = BeautifulSoup(content, "html.parser")

    found_units = []

    # Extract from both bedroom-type-1 and bedroom-type-2
    # for bedroom_type in ["bedroom-type-1", "bedroom-type-2"]:
    for bedroom_type in ["bedroom-type-2"]:
        target_div = soup.find("div", id=bedroom_type)

        if not target_div:
            print(f"Div with id '{bedroom_type}' not found")
            continue

        units = target_div.find_all("div", class_="unit")
        print(f"Found {len(units)} units in {bedroom_type}:")

        for i, unit in enumerate(units, 1):
            info = extract_unit_info(unit)
            if info:
                price = info.get("price", "N/A")
                sqft = info.get("square_feet", "N/A")
                availability = info.get("availability", "N/A")
                # Add bedroom type to the tuple for better identification
                bedroom_label = "1BR" if bedroom_type == "bedroom-type-1" else "2BR"
                found_units.append((bedroom_label, price, sqft, availability))

    return sorted(found_units)


def extract_info(scraper, url):
    try:
        response = scraper.get(url, timeout=10)

        if response.status_code != 200:
            print(f"Failed to retrieve page. Status code: {response.status_code}")
            return

        return extract_info_from_page_content(response.content)
    except Exception as e:
        print(f"Exception: {e}")
        return


def main():
    if len(sys.argv) != 3:
        print("Usage: python main.py <url> <instance-name>")
        print(
            "Example: python main.py 'https://www.equityapartments.com/new-york-city/jersey-city/the-pier-apartments' 'The Pier Apartments'"
        )
        sys.exit(1)

    url = sys.argv[1]
    instance_name = sys.argv[2]

    scraper = cloudscraper.create_scraper()
    prev_found_units = []
    scraper_created_time = time.time()
    scraper_renewal_interval = 10 * 60

    print("Starting apartment monitoring loop...")
    print(f"Monitoring: {instance_name}")
    print(f"URL: {url}")
    print("Checking for changes every minute (±10 seconds)...")
    print("Renewing scraper session every 10 minutes (±2 minutes)...")

    while True:
        try:
            current_time = time.time()
            time_since_scraper_creation = current_time - scraper_created_time

            renewal_offset = random.gauss(
                0, 120
            )  # Normal distribution with std=2 minutes
            actual_renewal_time = scraper_renewal_interval + renewal_offset

            if time_since_scraper_creation >= actual_renewal_time:
                print(
                    f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] Creating new scraper session..."
                )
                scraper = cloudscraper.create_scraper()
                scraper_created_time = current_time
                print("New scraper session created")

            found_units = extract_info(scraper, url)

            # # Randomly drop 50% of the found units
            # if found_units:
            #     num_to_keep = len(found_units) // 2
            #     found_units = random.sample(found_units, num_to_keep)

            if found_units != prev_found_units:
                print(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] Changes detected!")
                print("Current units:")
                for i, (bedroom_type, price, sqft, availability) in enumerate(
                    found_units, 1
                ):
                    print(
                        f"  Unit {i}: {bedroom_type} | {price} | {sqft} | {availability}"
                    )

                send_pushover_notification(found_units, prev_found_units, instance_name)

                prev_found_units = found_units
            else:
                print(f"[{time.strftime('%Y-%m-%d %H:%M:%S')}] No changes detected")

            offset = random.gauss(0, 20)
            sleep_time = 70 + offset

            # offset = random.gauss(0, 5)
            # sleep_time = 10 + offset

            # Ensure sleep time is positive
            sleep_time = max(1, sleep_time)

            print(f"Waiting {sleep_time:.1f} seconds until next check...")
            time.sleep(sleep_time)

        except KeyboardInterrupt:
            print("\nMonitoring stopped by user")
            break
        except Exception as e:
            print(f"Error in main loop: {e}")
            print("Waiting 30 seconds before retrying...")
            time.sleep(30)


if __name__ == "__main__":
    main()
