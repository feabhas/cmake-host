# Feabhas CMake Project Notes

# Basic Usage

The Feahbas project build process uses [CMake](https://cmake.org/) as the underlying
build system. CMake is itself a build system generator and we have configured
it to generate the build files used by [GNU Make](https://www.gnu.org/software/make/).

Using CMake is a two step process: generate build files and then build. To simplify 
this and to allow you to add additional source and header files we have 
created a front end script to automate the build.

You can add additional C/C++ source and header files to the `src` directory. If 
you prefer you can place your header files in the `include` directory.

## To build the application

From within VS Code you can use the keyboard shortcut `Ctrl-Shift-B` 
to run one of the build tasks:
    * **Build** standard build
    * **Clean** to remove object and executable files
    * **Reset** to regenerate the CMake build files

To run the application use `Ctrl-Shift-P` shortcut key, enter test in 
the search field and then select `Tasks: Run Test Task` from the list of tasks shown. 
The next time you use `Ctrl-Shift-P` the `Tasks: Run Test Task` will be at the top of the list. 

Run tasks are project specific. For the host:
    * **Run Application** to run the built executable
    
From the command line at the project root do:

```
$ ./build.sh
```

This will generate the file `build/debug/Application`.

You can add a `-v` option see the underlying build commands:

```
$ ./build.sh -v
```

## To clean the build

To delete all object files and recompile the complete project use
the `clean` option:

```
$ ./build.sh clean
```

To clean the entire build directory and regenerate a new build configuration use
the `reset` option:

```
$ ./build.sh reset
```

## VS Debug

To debug your code with the interactive (visual) debugger press the `<F5>` key or use the
**Run -> Start Debugging** menu.

The debug sessions with stop at the entry to the `main` function and may display a 
red error box saying:

```
Exception has occured.
```

This is normal: just close the warning popup and use the debug icon commands at the top 
manage the debug system. The icons are (from left to right):
  **continue**, **stop over**, **step into**, **step return**, **restart** and **quit**

# Using a template starter project

Some courses provide starter template projects alongside solutions. These will
be stored in a folder called `exercises` in one of the standard locations shown 
at the end of this section. 

To select one of the exercise teplates run the script:
```
$ ./build-template.sh
```

This will display a numbered list of template folders and ask you to select one.

Alternatively the script can be run with a partial letter case insensitive match of 
the start of the name of the template. For example to select a template called 
`E-meters` run the command:
```
$ ./build-template.sh e-m
```

As long as the name prefix is unique the template will be used. If the prefix is not
matched the numbered selection list will be shown.

**NOTE:** this will copy all files in the `src` and `include` directories to the `src.bak` directory having
removed any files already present in `src.bak`.

On the pre-built VM images the exercises are stored in the home directory.

When working with a Docker image you will either be given an archive of the
exercises, a web link to download the archive, or a link to clone a GIT repo. 

Once you have identified your local copy of the `exercises` you should 
copy this folder into the workspace (it will contain sub-folders for
the exercise `templates` and `solutions`)

# Building an exercise solution

To build any of the exercise solutions run the script:
```
$ ./build-one.sh N 
```
where `N` is the exercise number.

**NOTE:** this will copy all files in the `src` and `include` directories to the `src.bak` directory having
removed any files already present in `src.bak`.

n the pre-built VM images the solutions are stored in the home directory.

When working with a Docker image you will either be given an archive of the
solutions, an archive of the exercises, a web link to download the archive,
or a link to clone a GIT repo. 

Once you have identified your local copy of the `solutions` you should 
copy this folder into the workspace.

# Static analysis using clang-tidy

The CMake build scripts create a `clang-tidy` target in the generated build files if
`clang-tidy` is in the command search path (`$PATH` under Linux).

To check all of the build files run the command:
```
$ ./build.sh clang-tidy
```

To run `clang-tidy` as part of the compilation process edit the `CMakeLists.txt` file
and uncomment the line starting with `set(CMAKE_CXX_CLANG_TIDY`.

