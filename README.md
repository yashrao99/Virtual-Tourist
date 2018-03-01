# Virtual-Tourist
Udacity iOS Nanodegree Virtual Tourist Project

This Virtual Toursit focused on utilizing Core Data to persist user information.

The user can drop a pin at a certain location (Pin entity in coreData). The pins are persisted between different 
sessions of using the app. The edit button in the navigation bar will configure the edit mode, which allows the user to tap
on a pin in order to delete the selected pin from core data.

When the pin is pressed, a segue is performed transferring the pin location information and making a RESTful API request
to Flickr which downloads public images within a 5 km radius of the latitude/longitude of the selected pin.

Up to 21 random images are appended into the CoreData Photo entity at a time and the pictures are presented as a collection
view. If no photos are selected at the collection View IndexPath, the button at the bottom will refresh the collection view
with 21 random images (if more than 21 are available). If photos in the collection view are selected, the button will delete
those photos from the collection view and coreData storage.
