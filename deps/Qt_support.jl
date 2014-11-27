# Load Qt framework
# adjust qtlibdir path and version info if necessary

@osx_only begin
    const qtlibdir = joinpath(homedir(),"Qt/5.3/clang_64/lib/")
    const QtCore = joinpath(qtlibdir,"QtCore.framework/")
    const QtWidgets = joinpath(qtlibdir,"QtWidgets.framework/")

    addHeaderDir(qtlibdir; isFramework = true, kind = C_System)

    dlopen(joinpath(QtCore,"QtCore_debug"))
    addHeaderDir(joinpath(QtCore,"Headers"), kind = C_System)
    addHeaderDir(joinpath(QtCore,"Headers/5.3.2/QtCore"))
    cxxinclude(joinpath(QtCore,"Headers/5.3.2/QtCore/private/qcoreapplication_p.h"))

    dlopen(joinpath(QtWidgets,"QtWidgets"))
    addHeaderDir(joinpath(QtWidgets,"Headers"), kind = C_System)
end

@linux_only begin
    const qtincdir = "/usr/include/qt5"
    const qtlibdir = "/usr/lib/x86_64-linux-gnu/"

    addHeaderDir(qtincdir, kind = C_System)
    addHeaderDir(QtWidgets, kind = C_System)

    dlopen(joinpath(qtlibdir,"libQt5Core.so"), RTLD_GLOBAL)
    dlopen(joinpath(qtlibdir,"libQt5Gui.so"), RTLD_GLOBAL)
    dlopen(joinpath(qtlibdir,"libQt5Widgets.so"), RTLD_GLOBAL)
end

cxxinclude("QApplication", isAngled=true)
cxxinclude("QMessageBox", isAngled=true)
cxxinclude("QFileDialog", isAngled=true)

# Qt GUI framework
# http://qt-project.org/doc/qt-5/qapplication.html
# http://qt-project.org/doc/qt-5/qfiledialog.html#getOpenFileName

# QString conversion
# http://qt-project.org/forums/viewthread/4732
# http://qt-project.org/doc/qt-5/qstring.html#details

# Create a QApplication GUI object
#     const a = "FileOpen"
#     argv = Ptr{Uint8}[pointer(a),C_NULL]       # const char** argv
#     argc = [int32(1)]                          # int agrc
#     app = @cxx QApplication(*(pointer(argc)),pointer(argv))
#     ... call QWidget or method
#     @cxx app->processEvents()


# convertQString
cxx"""
    const char* convertQString(QString myString) {
        std::string s = myString.toLocal8Bit().constData();
        // alternatives: toAscii(), toLatin1(), toUtf8()
        // std::cout << s << std::endl;
        const char* c = s.c_str();
        return(c);
    }
"""

# Open file with QFileDialog, returns Julia String
function getOpenFileName()
    const a = "FileOpen"
    argv = Ptr{Uint8}[pointer(a),C_NULL]  # const char** argv
    argc = [int32(1)]                     # int agrc
    app = @cxx QApplication(*(pointer(argc)),pointer(argv))
    Qname = @cxx QFileDialog::getOpenFileName(cast(C_NULL, pcpp"QWidget"),
       pointer("Open File..."), pointer(homedir()), pointer("Files (*.*)"));
    bytestring(@cxx convertQString(Qname));  # somewhow necessary to remove the first string
    filename = bytestring(@cxx convertQString(Qname))
end

# Open file with QFileDialog, returns Julia String
function getSaveFileName()
    const a = "FileSave"
    argv = Ptr{Uint8}[pointer(a),C_NULL]  # const char** argv
    argc = [int32(1)]                     # int agrc
    app = @cxx QApplication(*(pointer(argc)),pointer(argv))
    Qname = @cxx QFileDialog::getSaveFileName(cast(C_NULL, pcpp"QWidget"),
       pointer("Save File..."), pointer(homedir()), pointer("Files (*.*)"));
    bytestring(@cxx convertQString(Qname));  # somewhow necessary to remove the first string
    filename = bytestring(@cxx convertQString(Qname))
end
