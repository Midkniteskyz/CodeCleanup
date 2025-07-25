import time
import pandas as pd
from geopy.geocoders import Nominatim

# Initialize geolocator
geolocator = Nominatim(user_agent="geoapiExercises")

# List of addresses
addresses = [
    "5601 East La Palma Avenue, Anaheim, CA, 92807",
    "615 N 48th St, Phoenix, AZ, 85008",
    "123 S Marengo Ave, Pasadena, CA 91101",
    "5495 E La Palma Ave, Anaheim, CA, 92807",
    "3409 E Foothill Blvd, Pasadena, CA 91107",
    "3431 Grand Oaks Suite 102, Corona, CA 92881",
    "2701 Harbor Blvd.,Suite E-2,Costa Mesa CA 92626",
    "10970 Jefferson Blvd, Culver City, CA 90230",
    "2871 W. 120th Street,Hawthorne, CA 90250",
    "15378 Alton Parkway,Irvine, CA 92618",
    "510 Canal St., King City, CA 93930",
    "1330 South Beach Blvd,Suite B,La Habra, CA 90631",
    "28121 Crown Valley Pkwy,Suite K,Laguna Niguel, CA 92677",
    "232 Reservation Rd. #232, Marina, CA 93933",
    "4330 E. Mills Circle,Ontario, CA, 91764",
    "3743 W. Chapman Avenue,#C,Orange, CA 92868",
    "1660 E Gonzales Rd., Oxnard, CA 93036",
    "39575 Trade Center Drive, Palmdale, CA 93551",
    "9980 Alabama St. Suite F1,Redlands, CA 92374",
    "3790 Tyler St., Riverside, CA 92503",
    "1141 S. Main St., Salinas, CA 93901",
    "5000 Van Nuys Blvd #100, Sherman Oaks, CA 91403",
    "2600 Cherry Ave.,Signal Hill CA 90755",
    "2691 Tapo Canyon Road,Suite E,Simi Valley, CA 93063",
    "315 Gabilan Dr., Soledad, CA 93960",
    "11-A East Hillcrest Dr., Thousand Oaks, CA 91360",
    "19780 Hawthorne Blvd, Torrance, CA 90503",
    "2979 El Camino Real, Tustin, CA 92782",
    "2646 E Garvey Ave South,Suite F,West Covina, CA 91791",
    "24165 Magic Mountain Pkwy, Santa Clarita CA 91355",
    "11776 Santa Monica Blvd. Suite 117,Los Angeles, CA 90025",
    "Ackerman Student Union,1st Floor 308 Westwood Plaza,Los Angeles, Ca 90095"
]

# Get latitude and longitude for each address with a delay to avoid throttling
locations = []
for address in addresses:
    location = geolocator.geocode(address)
    if location:
        locations.append((address, location.latitude, location.longitude))
    else:
        locations.append((address, None, None))
    time.sleep(1)  # delay to prevent being blocked

# Convert to DataFrame and save as CSV
df = pd.DataFrame(locations, columns=["Address", "Latitude", "Longitude"])
df.to_csv("address_coordinates.csv", index=False)

print("Coordinates have been saved to 'address_coordinates.csv'.")
