#include "ffmpeg.h"
#include <jni.h>

JNIEXPORT jint JNICALL
               Java_com_mabeijianxi_jianxiffmpegcmd_MainActivity_ffmpegRun(JNIEnv *env, jobject type,jobjectArray commands){
    int argc = (*env)->GetArrayLength(env,commands);
    char *argv[argc];
    int i;
    for (i = 0; i < argc; i++) {
        jstring js = (jstring) (*env)->GetObjectArrayElement(env,commands, i);
        argv[i] = (char *) (*env)->GetStringUTFChars(env,js, 0);
    }
    nb_filtergraphs = 0;
    progress_avio = NULL;

    input_streams = NULL;
    nb_input_streams = 0;
    input_files = NULL;
    nb_input_files = 0;

    output_streams = NULL;
    nb_output_streams = 0;
    output_files = NULL;
    nb_output_files = 0;
    return jxRun(argc,argv);
}

JNIEXPORT jstring JNICALL
Java_com_mabeijianxi_jianxiffmpegcmd_MainActivity_getFFmpegConfig(JNIEnv *env, jobject instance) {

    char info[10000] = {0};
    sprintf(info, "%s\n", avcodec_configuration());
    return (*env)->NewStringUTF(env,info);

}