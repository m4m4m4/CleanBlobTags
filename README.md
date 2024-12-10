This scripts removes all blob tags from an azure blob storage container based on a tag filter in the script. It performs it in chunks of 1000. 
Set the MaxIterations parameter to something like 500 and it will perform the cleaning for 500K files, which usually takes at least 6 hours.
If there are no files left with the tag criteria the script will terminate
