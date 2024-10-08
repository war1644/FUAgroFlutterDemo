#pragma once

#include "include/IAgoraMediaEngine.h"
#include "include/IAgoraRtcEngine.h"
#include "include/AgoraMediaBase.h"

#include <jni.h>
#include <vector>

namespace agora {
    class VideoFrameObserver : public media::IVideoFrameObserver {
    public:
        VideoFrameObserver(JNIEnv *env, jobject jCaller, long long EngineHandle);

        virtual ~VideoFrameObserver();

    public:
        bool onCaptureVideoFrame(VideoFrame &videoFrame) override;

        bool onPreEncodeVideoFrame(VideoFrame &videoFrame) override;

        bool onSecondaryCameraCaptureVideoFrame(VideoFrame &videoFrame) override;

        bool onSecondaryPreEncodeCameraVideoFrame(VideoFrame &videoFrame) override;

        bool onScreenCaptureVideoFrame(VideoFrame &videoFrame) override;

        bool onPreEncodeScreenVideoFrame(VideoFrame &videoFrame) override;

        bool onMediaPlayerVideoFrame(VideoFrame &videoFrame, int mediaPlayerId) override;

        bool onSecondaryScreenCaptureVideoFrame(VideoFrame &videoFrame) override;

        bool onSecondaryPreEncodeScreenVideoFrame(VideoFrame &videoFrame) override;

        bool onRenderVideoFrame(const char *channelId, rtc::uid_t remoteUid,
                                VideoFrame &videoFrame) override;

        bool onTranscodedVideoFrame(VideoFrame &videoFrame) override;


        VIDEO_FRAME_PROCESS_MODE getVideoFrameProcessMode() override;


        media::base::VIDEO_PIXEL_FORMAT getVideoFormatPreference() override;

        bool getRotationApplied() override;

        bool getMirrorApplied() override;

        uint32_t getObservedFramePosition() override;


    private:
        std::vector<jbyteArray> NativeToJavaByteArray(JNIEnv *env,
                                                      VideoFrame &videoFrame);

        jobject NativeToJavaVideoFrame(JNIEnv *env, VideoFrame &videoFrame,
                                       std::vector<jbyteArray> jByteArray);

    private:
        JavaVM *jvm = nullptr;

        jobject jCallerRef;
        jmethodID jOnCaptureVideoFrame;
        jmethodID jOnRenderVideoFrame;
        jmethodID jOnPreEncodeVideoFrame;
        jmethodID jGetVideoFormatPreference;
        jmethodID jGetRotationApplied;
        jmethodID jGetMirrorApplied;
        jmethodID jGetObservedFramePosition;

        jclass jVideoFrameClass;
        jmethodID jVideoFrameInit;

        jclass jVideoFrameTypeClass;
        jmethodID jOrdinal;

        long long engineHandle;
    };
} // namespace agora
