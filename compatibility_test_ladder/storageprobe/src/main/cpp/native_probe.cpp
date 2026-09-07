#include <jni.h>

#include <cerrno>
#include <cstring>
#include <fcntl.h>
#include <limits.h>
#include <string>
#include <sys/stat.h>
#include <unistd.h>

namespace {

std::string errnoText() {
    const int value = errno;
    return std::to_string(value) + ":" + std::strerror(value);
}

std::string pathState(const char* label, const std::string& path) {
    struct stat st{};
    const int result = ::stat(path.c_str(), &st);
    std::string out = label;
    out += ".path=" + path + "\n";
    out += label;
    if (result == 0) {
        out += ".exists=true,mode=" + std::to_string(st.st_mode & 07777) +
               ",uid=" + std::to_string(st.st_uid) +
               ",gid=" + std::to_string(st.st_gid) + "\n";
    } else {
        out += ".exists=false,errno=" + errnoText() + "\n";
    }
    return out;
}

}  // namespace

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_duplikaladder_storageprobe_MainActivity_nativeProbe(
        JNIEnv* env, jclass, jstring directory) {
    const char* raw = env->GetStringUTFChars(directory, nullptr);
    const std::string dir(raw == nullptr ? "" : raw);
    if (raw != nullptr) env->ReleaseStringUTFChars(directory, raw);

    std::string out;
    out += "native.directory=" + dir + "\n";
    out += pathState("native.directory", dir);

    const std::string canonical = [&]() {
        char buffer[PATH_MAX]{};
        return ::realpath(dir.c_str(), buffer) == nullptr
                   ? std::string("ERROR errno=") + errnoText()
                   : std::string(buffer);
    }();
    out += "native.canonical=" + canonical + "\n";

    if (::mkdir(dir.c_str(), 0771) == 0) {
        out += "native.mkdir=true\n";
    } else if (errno == EEXIST) {
        out += "native.mkdir=true,alreadyExists=true\n";
    } else {
        out += "native.mkdir=false,errno=" + errnoText() + "\n";
    }
    out += pathState("native.afterMkdir", dir);

    const std::string file = dir + "/native-probe.bin";
    errno = 0;
    const int fd = ::open(file.c_str(), O_CREAT | O_WRONLY | O_TRUNC | O_CLOEXEC, 0600);
    if (fd < 0) {
        out += "native.open=false,errno=" + errnoText() + "\n";
        return env->NewStringUTF(out.c_str());
    }
    out += "native.open=true\n";

    const char payload[] = "native-storage-probe";
    const ssize_t written = ::write(fd, payload, sizeof(payload) - 1);
    if (written == static_cast<ssize_t>(sizeof(payload) - 1)) {
        out += "native.write=true\n";
    } else {
        out += "native.write=false,errno=" + errnoText() + "\n";
    }
    if (::close(fd) == 0) {
        out += "native.close=true\n";
    } else {
        out += "native.close=false,errno=" + errnoText() + "\n";
    }
    out += pathState("native.file", file);
    return env->NewStringUTF(out.c_str());
}
