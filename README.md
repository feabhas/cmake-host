# Feabhas CMake Project Notes

# Basic Usage

The Feahbas project build process uses [CMake](https://cmake.org/) as the underlying
build system. CMake is itself a build system generator and we have configured
it to generate the build files used by [GNU Make](https://www.gnu.org/software/make/)
under Linux or Ninja under Windows when used as a Visual Studio CMake
project.

On Linux hosts the project has been configured with VS Code tasks to build and 
debug a Linux native executable. Supporting scripts provide command
line support for building the executable (see later).

On a Windows host you use VS Code and WSL2 to build Linux executables using
the VS code task and build scripts (you will need to add
a C++ compiler and make utlity to the bare WSL2 Linux image). 

On Windows hosts you can also use Visual Studio to build a Windows native 
executable using the same CMake configuration file (`CMakeLists.txt`) which includes
options to support the MSVC build system. The `CMakeSettings.json` file
is used by Visual Studio to mage the CMake build.

Using CMake is a two step process: generate build files and then build. To simplify 
this and to allow you to add additional source and header files we have 
created a front end script to automate the build.

You can add additional C/C++ source and header files to the `src` directory. If 
you prefer you can place your header files in the `include` directory.

## Using VS Code keys

VS Code tasks and launch scripts are defined so that `Ctrl-Shift-B` will present a 
list of build tasks:

   * **Build** standard build
   * **Clean** removes object files and executables
   * **Reset** regenerate the CMake build files
   
To run the application use `Ctrl-Shift-P` shortcut key, enter test in 
the search field and then select `Tasks: Run Test Task` from the list of tasks shown. 
This will display a list of run options: choose `Run Application`. The next time 
you use `Ctrl-Shift-P` the `Tasks: Run Test Task` will be at the top of the list. 

To debug your code with the interactive (visual) debugger press the `<F5>` key or use the
**Run -> Start Debugging** menu.

The debug sessions will stop at the entry to the `main` function and *may* display a 
red error box saying:

```
Exception has occured.
```

This is normal: just close the warning popup and use the debug icon commands at the top 
manage the debug system. The icons are (from left to right):
  **continue**, **stop over**, **step into**, **step return**, **restart** and **quit**

## To build the application from a Linux shell

At the project root do:

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

# Building an exercise solution

To build any of the exercise solutions run the script:

```
$ ./build-one.sh <N> 
```

where `<N>` is the exercise number. The solutions should be in a folder called 
`solutions` at the same level as your project workspace.

**NOTE:** this script will copy all files in the `src` folder to the `src.bak` 
folder having removed any files already present in `src.bak`.

