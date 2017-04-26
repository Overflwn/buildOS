# buildOS
A simplistic GUI front-end for ComputerCraft.
Not recommended for advanced programmers or even anyone who is able to program,
as it isn't really as advanced as lets say cLinux.

If you are a CC newbie and just want to use it for roleplaying purposes or saving your
"Minecraft documents" for whatever reason, you might light this one.

[Check out the forum post for more information]()

## Basic implemented API and function explanation

1. Permission module
  - perm.user.add(name, password)
    Registers a new user using the given name and password.
  - perm.user.login(name, password)
    Logs into an existing user.
  - perm.user.switch() [Will be removed later on]
    Switches the user to root and back when recalled
  - perm.user.getLoggedUser()
    Returns the name of the current logged in user
  - perm.user.remove(name, password)
    Removes the specified user if either of the following:
	  1. The logged in user is root
	  2. The password matches
  - perm.permission.check(name, path)
    Checks whether the specified user is able to modify a certain directory
	Returns either of the following:
	  1. "x" = Read-Only
	  2. "wx" = Full access
2. Filesystem module:
  - Nothing is really changed, except the fact that it uses perm.permission.check
3. Package module:
  - Puts the function 'require' and 'unload' to _G
  - requrie(name):
    1. Checks if the specified API is already loaded:
	  - If not it loads it and returns it to you
	  - If yes it returns it directly
  - unload(name):
    1. Simply unloads a loaded API
