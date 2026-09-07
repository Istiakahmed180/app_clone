#include <jni.h>

extern "C" JNIEXPORT jstring JNICALL
Java_com_example_duplikaladder_level7fixture_MainActivity_nativeMarker(JNIEnv* env, jclass) {
    return env->NewStringUTF("abi-native-loaded");
}
