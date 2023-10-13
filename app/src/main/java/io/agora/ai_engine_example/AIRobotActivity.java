package io.agora.ai_engine_example;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.agora.aigc.sdk.AIGCServiceCallback;
import io.agora.aigc.sdk.constants.HandleResult;
import io.agora.aigc.sdk.constants.Language;
import io.agora.aigc.sdk.constants.ServiceCode;
import io.agora.aigc.sdk.constants.ServiceEvent;
import io.agora.aigc.sdk.constants.Vad;
import io.agora.aigc.sdk.model.Data;
import io.agora.aigic_service_example.R;
import io.agora.aigic_service_example.databinding.AiRobotActivityBinding;
import io.agora.rtc2.ChannelMediaOptions;
import io.agora.rtc2.IAudioFrameObserver;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;
import io.agora.rtc2.audio.AudioParams;


public class AIRobotActivity extends Activity implements AIGCServiceCallback, IAudioFrameObserver {
    private final String TAG = "AIGCService-" + AIRobotActivity.class.getSimpleName();
    private AiRobotActivityBinding binding;

    private boolean mIsSpeaking = false;
    private boolean mVoiceChangeEnable = false;
    private boolean mDownload = false;
    private boolean mMute = false;
    private Language mLanguage = Language.ZH_CN;
    private int mMaxRoleNum = 0;
    private int mCurrentRoleIndex = 0;
    private File mPcmFile;
    private OutputStream mPcmOs;
    private ExecutorService mExecutorCacheService;
    private ExecutorService mExecutorService;
    private RtcEngine mRtcEngine;
    private final static String CHANNEL_ID = "TestAgoraAIGC";

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = AiRobotActivityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        enableUi(true);
        initData();
        initRtc(getApplicationContext());
        initAIGCService();
    }


    private void initData() {
        mExecutorCacheService = new ThreadPoolExecutor(Integer.MAX_VALUE, Integer.MAX_VALUE,
                0, TimeUnit.SECONDS,
                new LinkedBlockingDeque<>(), Executors.defaultThreadFactory(), new ThreadPoolExecutor.AbortPolicy());
        mExecutorService = new ThreadPoolExecutor(1, 1,
                0, TimeUnit.SECONDS,
                new LinkedBlockingDeque<>(), Executors.defaultThreadFactory(), new ThreadPoolExecutor.AbortPolicy());
        try {
            mPcmFile = new File(getApplication().getExternalCacheDir().getPath() + "/temp/ui-test.pcm");
            Log.i(TAG, "pcm file path:" + mPcmFile.getAbsolutePath());
            mPcmOs = new FileOutputStream(mPcmFile);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    public boolean initRtc(Context context) {
        if (mRtcEngine == null) {
            try {
                RtcEngineConfig rtcEngineConfig = new RtcEngineConfig();
                rtcEngineConfig.mContext = context;
                rtcEngineConfig.mAppId = KeyCenter.APP_ID;
                rtcEngineConfig.mChannelProfile = io.agora.rtc2.Constants.CHANNEL_PROFILE_LIVE_BROADCASTING;
                rtcEngineConfig.mEventHandler = new IRtcEngineEventHandler() {
                    @Override
                    public void onJoinChannelSuccess(String channel, int uid, int elapsed) {
                        Log.i(TAG, "onJoinChannelSuccess channel:" + channel + " uid:" + uid + " elapsed:" + elapsed);
                        mRtcEngine.registerAudioFrameObserver(AIRobotActivity.this);
                    }

                    @Override
                    public void onLeaveChannel(RtcStats stats) {
                        Log.i(TAG, "onLeaveChannel stats:" + stats);
                    }

                    @Override
                    public void onUserOffline(int uid, int reason) {
                        Log.i(TAG, "onUserOffline uid:" + uid + " reason:" + reason);
                    }

                    @Override
                    public void onUserJoined(int uid, int elapsed) {
                        Log.i(TAG, "onUserJoined uid:" + uid + " elapsed:" + elapsed);
                    }

                };
                rtcEngineConfig.mAudioScenario = io.agora.rtc2.Constants.AudioScenario.getValue(io.agora.rtc2.Constants.AudioScenario.DEFAULT);
                mRtcEngine = RtcEngine.create(rtcEngineConfig);


                mRtcEngine.setParameters("{\"rtc.enable_debug_log\":true}");

                mRtcEngine.enableAudio();
                mRtcEngine.setAudioProfile(
                        io.agora.rtc2.Constants.AUDIO_PROFILE_DEFAULT, io.agora.rtc2.Constants.AUDIO_SCENARIO_GAME_STREAMING
                );
                mRtcEngine.setDefaultAudioRoutetoSpeakerphone(true);


                mRtcEngine.setPlaybackAudioFrameParameters(16000, 1, io.agora.rtc2.Constants.RAW_AUDIO_FRAME_OP_MODE_READ_WRITE, 640);

                mRtcEngine.setRecordingAudioFrameParameters(16000, 1, io.agora.rtc2.Constants.RAW_AUDIO_FRAME_OP_MODE_READ_WRITE, 640);

                int ret = mRtcEngine.joinChannel(
                        KeyCenter.getRtcToken(CHANNEL_ID, KeyCenter.getUserUid()),
                        CHANNEL_ID,
                        KeyCenter.getUserUid(),
                        new ChannelMediaOptions() {{
                            publishMicrophoneTrack = false;
                            publishCustomAudioTrack = false;
                            autoSubscribeAudio = true;
                            clientRoleType = io.agora.rtc2.Constants.CLIENT_ROLE_BROADCASTER;
                        }});
            } catch (Exception e) {
                e.printStackTrace();
                return false;
            }
        }
        return true;
    }

    private void initAIGCService() {
        AIGCServiceManager.getInstance().initAIGCService(this, getApplicationContext());
    }


    @Override
    protected void onResume() {
        super.onResume();
        initView();
        handlePermission();

    }

    private void handlePermission() {

        // 需要动态申请的权限
        String permission = Manifest.permission.RECORD_AUDIO;

        //查看是否已有权限
        int checkSelfPermission = ActivityCompat.checkSelfPermission(getApplicationContext(), permission);

        if (checkSelfPermission == PackageManager.PERMISSION_GRANTED) {
            //已经获取到权限  获取用户媒体资源

        } else {

            //没有拿到权限  是否需要在第二次请求权限的情况下
            // 先自定义弹框说明 同意后在请求系统权限(就是是否需要自定义DialogActivity)
            if (ActivityCompat.shouldShowRequestPermissionRationale(this, permission)) {

            } else {
                appRequestPermission();
            }
        }

    }

    private void appRequestPermission() {
        String[] permissions = new String[]{
                Manifest.permission.RECORD_AUDIO,
        };
        requestPermissions(permissions, 1);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (grantResults[0] == PackageManager.PERMISSION_GRANTED) {

        }
    }


    private void enableUi(boolean enable) {
        binding.btnSpeak.setEnabled(enable);
        binding.btnVoiceChange.setEnabled(enable);
        binding.btnSwitchLang.setEnabled(enable);
        binding.btnExit.setEnabled(enable);
        binding.btnMute.setEnabled(enable);
        binding.btnSwitchAiRole.setEnabled(enable);
    }

    private void initView() {
        binding.btnSpeak.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mIsSpeaking) {
                    mIsSpeaking = false;
                    binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.start_speak));
                    updateRoleSpeak(false);
                    AIGCServiceManager.getInstance().getAIGCService().stop();
                } else {
                    mIsSpeaking = true;
                    binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.end_speak));
                    updateRoleSpeak(true);
                    AIGCServiceManager.getInstance().getAIGCService().start();
                }

            }
        });

        binding.btnVoiceChange.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (mVoiceChangeEnable) {
                    mVoiceChangeEnable = false;
                    binding.btnVoiceChange.setText(R.string.voice_change_enable);
                } else {
                    mVoiceChangeEnable = true;
                    binding.btnVoiceChange.setText(R.string.voice_change_disable);
                }
            }
        });

        binding.btnSwitchLang.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (Language.ZH_CN == mLanguage) {
                    mLanguage = Language.EN_US;
                    binding.btnSwitchLang.setText(R.string.lang_switch_cn);
                } else {
                    mLanguage = Language.ZH_CN;
                    binding.btnSwitchLang.setText(R.string.lang_switch_en);
                }
                mIsSpeaking = false;
                binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.start_speak));
            }
        });

        binding.btnExit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                enableUi(false);
                AIGCServiceManager.getInstance().destroy();
            }
        });

        binding.btnDownload.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mDownload) {
                    mDownload = true;
                    binding.btnDownload.setText(R.string.cancel_download);
                } else {
                    mDownload = false;
                    binding.btnDownload.setText(R.string.download);
                }
            }
        });


        binding.btnMute.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mMute) {
                    mMute = true;
                    binding.btnMute.setText(R.string.unmute);
                } else {
                    mMute = false;
                    binding.btnMute.setText(R.string.mute);
                }
            }
        });

        binding.btnSwitchAiRole.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
            }
        });
    }

    public boolean updateRoleSpeak(boolean isSpeak) {
        int ret = io.agora.rtc2.Constants.ERR_OK;
        ret += mRtcEngine.updateChannelMediaOptions(new ChannelMediaOptions() {{
            publishMicrophoneTrack = isSpeak;
            publishCustomAudioTrack = isSpeak;
        }});
        return ret == io.agora.rtc2.Constants.ERR_OK;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onEventResult(@NonNull ServiceEvent serviceEvent, @NonNull ServiceCode serviceCode, @Nullable String s) {
        Log.i(TAG, "onEventResult serviceEvent:" + serviceEvent + " serviceCode:" + serviceCode + " s:" + s);
    }

    @Override
    public HandleResult onSpeech2TextResult(String roundId, Data<String> data, boolean b) {
        Log.i(TAG, "onSpeech2TextResult roundId:" + roundId + " data:" + data + " b:" + b);
        return HandleResult.CONTINUE;
    }

    @Override
    public HandleResult onLLMResult(String s, Data<String> data) {
        Log.i(TAG, "onLLMResult s:" + s + " data:" + data);
        return HandleResult.CONTINUE;
    }

    @Override
    public HandleResult onText2SpeechResult(String s, Data<byte[]> data, int i, int i1, int i2) {
        Log.i(TAG, "onText2SpeechResult s:" + s + " data:" + data + " i:" + i + " i1:" + i1 + " i2:" + i2);
        return HandleResult.CONTINUE;
    }


    @Override
    public boolean onRecordAudioFrame(String channelId, int type, int samplesPerChannel,
                                      int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer,
                                      long renderTimeMs, int avsync_type) {
        if (mIsSpeaking) {
            int length = buffer.remaining();
            byte[] origin = new byte[length];
            buffer.get(origin);
            buffer.flip();

            AIGCServiceManager.getInstance().getAIGCService().pushSpeechDialogue(origin, Vad.UNKNOWN);
        }
        return false;
    }

    @Override
    public boolean onPlaybackAudioFrame(String channelId, int type, int samplesPerChannel,
                                        int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer,
                                        long renderTimeMs, int avsync_type) {
        if (mIsSpeaking) {
        }
        return true;
    }

    @Override
    public boolean onMixedAudioFrame(String channelId, int type, int samplesPerChannel, int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer, long renderTimeMs, int avsync_type) {
        return false;
    }

    @Override
    public boolean onEarMonitoringAudioFrame(int type, int samplesPerChannel, int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer, long renderTimeMs, int avsync_type) {
        return false;
    }

    @Override
    public boolean onPlaybackAudioFrameBeforeMixing(String channelId, int userId, int type, int samplesPerChannel, int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer, long renderTimeMs, int avsync_type) {
        return false;
    }

    @Override
    public int getObservedAudioFramePosition() {
        return 0;
    }

    @Override
    public AudioParams getRecordAudioParams() {
        return null;
    }

    @Override
    public AudioParams getPlaybackAudioParams() {
        return null;
    }

    @Override
    public AudioParams getMixedAudioParams() {
        return null;
    }

    @Override
    public AudioParams getEarMonitoringAudioParams() {
        return null;
    }

}
