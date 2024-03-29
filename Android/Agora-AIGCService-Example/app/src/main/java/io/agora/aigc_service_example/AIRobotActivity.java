package io.agora.aigc_service_example;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.agora.aigc.sdk.AIGCServiceCallback;
import io.agora.aigc.sdk.constants.HandleResult;
import io.agora.aigc.sdk.constants.STTMode;
import io.agora.aigc.sdk.constants.ServiceCode;
import io.agora.aigc.sdk.constants.ServiceEvent;
import io.agora.aigc.sdk.constants.SpeechState;
import io.agora.aigc.sdk.constants.Vad;
import io.agora.aigc.sdk.model.Data;
import io.agora.aigc.sdk.model.ServiceVendor;
import io.agora.aigc.sdk.utils.RingBuffer;
import io.agora.aigc.sdk.utils.Utils;
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
    private ExecutorService mExecutorCacheService;
    private ExecutorService mExecutorService;
    private RtcEngine mRtcEngine;
    private RingBuffer mSpeechRingBuffer;
    private boolean mRingBufferReady;
    private String mPreTtsRoundId;
    private final static String CHANNEL_ID = "TestAgoraAIGC";
    private HistoryListAdapter mAiHistoryListAdapter;
    private List<HistoryModel> mHistoryDataList;
    private SimpleDateFormat mSdf;
    private boolean mAIGCServiceStarted;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = AiRobotActivityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        enableUi(false);
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

        if (null == mSpeechRingBuffer) {
            mSpeechRingBuffer = new RingBuffer(1024 * 1024 * 5);
        } else {
            mSpeechRingBuffer.clear();
        }
        mPreTtsRoundId = "";
        mSdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.getDefault());
        if (null == mHistoryDataList) {
            mHistoryDataList = new ArrayList<>();
        } else {
            mHistoryDataList.clear();
        }

        mAIGCServiceStarted = false;
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
                        mRtcEngine.muteLocalAudioStream(true);
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
                rtcEngineConfig.mAudioScenario = io.agora.rtc2.Constants.AUDIO_SCENARIO_GAME_STREAMING;
                mRtcEngine = RtcEngine.create(rtcEngineConfig);

                mRtcEngine.setParameters("{\"rtc.enable_debug_log\":true}");

                mRtcEngine.setParameters("{\n" +
                        "\n" +
                        "\"che.audio.enable.nsng\":true,\n" +
                        "\"che.audio.ains_mode\":2,\n" +
                        "\"che.audio.ns.mode\":2,\n" +
                        "\"che.audio.nsng.lowerBound\":80,\n" +
                        "\"che.audio.nsng.lowerMask\":50,\n" +
                        "\"che.audio.nsng.statisticalbound\":5,\n" +
                        "\"che.audio.nsng.finallowermask\":30\n" +
                        "}");

                mRtcEngine.enableAudio();
                mRtcEngine.setAudioProfile(
                        io.agora.rtc2.Constants.AUDIO_PROFILE_DEFAULT, io.agora.rtc2.Constants.AUDIO_SCENARIO_GAME_STREAMING
                );


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
        binding.btnExit.setEnabled(enable);
        binding.btnSendTextLlm.setEnabled(enable);
        binding.btnSendMessagesLlm.setEnabled(enable);
    }

    private void initView() {
        if (mAiHistoryListAdapter == null) {
            mAiHistoryListAdapter = new HistoryListAdapter(getApplicationContext(), mHistoryDataList);
            binding.aiHistoryList.setAdapter(mAiHistoryListAdapter);
            binding.aiHistoryList.setLayoutManager(new WrapContentLinearLayoutManager(getApplicationContext()));
            binding.aiHistoryList.addItemDecoration(new HistoryListAdapter.SpacesItemDecoration(10));
        } else {
            mHistoryDataList.clear();
            mAiHistoryListAdapter.notifyDataSetChanged();
        }

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
                    mSpeechRingBuffer.clear();
                    mRingBufferReady = false;
                    binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.end_speak));
                    updateRoleSpeak(true);
                    AIGCServiceManager.getInstance().getAIGCService().start();
                }
            }
        });


        binding.btnExit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                enableUi(false);
                AIGCServiceManager.getInstance().destroy();
            }
        });

        binding.btnSendTextLlm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mAIGCServiceStarted) {
                    Toast.makeText(AIRobotActivity.this, "请先开启语聊", Toast.LENGTH_LONG).show();
                    return;
                }
                AIGCServiceManager.getInstance().getAIGCService().pushTxtDialogue("你叫什么名字？", Utils.getSessionId());
            }
        });

        binding.btnSendMessagesLlm.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mAIGCServiceStarted) {
                    Toast.makeText(AIRobotActivity.this, "请先开启语聊", Toast.LENGTH_LONG).show();
                    return;
                }
                AIGCServiceManager.getInstance().getAIGCService().pushMessagesToLLM("[{\n" +
                        "\t\t\"role\": \"user\",\n" +
                        "\t\t\"content\": \"你想去郊游吗？\"\n" +
                        "\t}, {\n" +
                        "\t\t\"role\": \"assistant\",\n" +
                        "\t\t\"content\": \"好啊！我们什么时候去？\"\n" +
                        "\t},\n" +
                        "\t{\n" +
                        "\t\t\"role\": \"user\",\n" +
                        "\t\t\"content\": \"周日？\"\n" +
                        "\t}\n" +
                        "]", "{\n" +
                        "\t\"temperature\": 0.5,\n" +
                        "\t\"presence_penalty\": 0.9,\n" +
                        "\t\"frequency_penalty\": 0.9\n" +
                        "}", Utils.getSessionId());
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
        AIGCServiceManager.getInstance().destroy();
    }

    private byte[] getSpeechVoiceData(int length) {
        byte[] bytes = null;
        if (mRingBufferReady) {
            bytes = getSpeechBuffer(length);
        } else {
            //wait length*WAIT_AUDIO_FRAME_COUNT data
            if (mSpeechRingBuffer.size() >= length * 3) {
                mRingBufferReady = true;
                bytes = getSpeechBuffer(length);
            }
        }
        return bytes;
    }

    private byte[] getSpeechBuffer(int length) {
        if (mSpeechRingBuffer.size() < length) {
            return null;
        }
        Object o;
        byte[] bytes = new byte[length];
        for (int i = 0; i < length; i++) {
            o = mSpeechRingBuffer.take();
            if (null == o) {
                return null;
            }
            bytes[i] = (byte) o;
        }
        return bytes;
    }

    @Override
    public void onEventResult(@NonNull ServiceEvent event, @NonNull ServiceCode code, @Nullable String msg) {
        Log.i(TAG, "onEventResult event:" + event + " code:" + code + " msg:" + msg);
        if (event == ServiceEvent.INITIALIZE && code == ServiceCode.SUCCESS) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    enableUi(true);
                }
            });
            Log.i(TAG, "getRoles:" + Arrays.toString(AIGCServiceManager.getInstance().getAIGCService().getRoles()));
            Log.i(TAG, "getCurrentRole:" + AIGCServiceManager.getInstance().getAIGCService().getCurrentRole());
            AIGCServiceManager.getInstance().getAIGCService().setRole(AIGCServiceManager.getInstance().getAIGCService().getRoles()[0].getRoleId());

            Log.i(TAG, "getServiceVendors:" + AIGCServiceManager.getInstance().getAIGCService().getServiceVendors());
            ServiceVendor serviceVendor = new ServiceVendor();
            serviceVendor.setSttVendor(AIGCServiceManager.getInstance().getAIGCService().getServiceVendors().getSttList().get(0));
            serviceVendor.setLlmVendor(AIGCServiceManager.getInstance().getAIGCService().getServiceVendors().getLlmList().get(0));
            serviceVendor.setTtsVendor(AIGCServiceManager.getInstance().getAIGCService().getServiceVendors().getTtsList().get(0));
            AIGCServiceManager.getInstance().getAIGCService().setServiceVendor(serviceVendor);
            AIGCServiceManager.getInstance().getAIGCService().setSTTMode(STTMode.FREESTYLE);
        } else if (event == ServiceEvent.START && code == ServiceCode.SUCCESS) {
            mAIGCServiceStarted = true;
        } else if (event == ServiceEvent.STOP && code == ServiceCode.SUCCESS) {
            mAIGCServiceStarted = false;
        } else if (event == ServiceEvent.DESTROY && code == ServiceCode.SUCCESS) {

        }
    }

    @Override
    public HandleResult onSpeech2TextResult(String roundId, Data<String> result, boolean isRecognizedSpeech, ServiceCode code) {
        Log.i(TAG, "onSpeech2TextResult roundId:" + roundId + " result:" + result + " isRecognizedSpeech:" + isRecognizedSpeech + " code:" + code);
        updateHistoryList("用户发言：" + result.getData(), true, roundId, false, false);
        return HandleResult.CONTINUE;
    }


    @Override
    public HandleResult onLLMResult(String roundId, Data<String> answer, boolean isRoundEnd, int estimatedResponseTokens, ServiceCode code) {
        Log.i(TAG, "onLLMResult roundId:" + roundId + " answer:" + answer + " isRoundEnd:" + isRoundEnd + " estimatedResponseTokens:" + estimatedResponseTokens + " code:" + code);
        updateHistoryList(answer.getData(), true, roundId + "llm", true, true);
        return HandleResult.CONTINUE;
    }


    @Override
    public HandleResult onText2SpeechResult(String roundId, Data<byte[]> voice, int sampleRates, int channels, int bits, ServiceCode code) {
        Log.i(TAG, "onText2SpeechResult roundId:" + roundId + " voice:" + voice + " sampleRates:" + sampleRates + " channels:" + channels + " bits:" + bits + " code:" + code);
        if (!mPreTtsRoundId.equalsIgnoreCase(roundId)) {
            mSpeechRingBuffer.clear();
            mRingBufferReady = false;
        }
        mPreTtsRoundId = roundId;

        final byte[] voices = voice.getData();
        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {
                if (null != voices) {
                    for (byte b : voices) {
                        mSpeechRingBuffer.put(b);
                    }
                }
            }
        });

        return HandleResult.CONTINUE;
    }

    @Override
    public void onSpeechStateChange(SpeechState state) {
        if (SpeechState.START == state) {
            AIGCServiceManager.getInstance().getAIGCService().interrupt();
        }
    }

    @Override
    public boolean onRecordAudioFrame(String channelId, int type, int samplesPerChannel,
                                      int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer,
                                      long renderTimeMs, int avsync_type) {
        if (mIsSpeaking && mAIGCServiceStarted) {
            int length = buffer.remaining();
            byte[] origin = new byte[length];
            buffer.get(origin);
            buffer.flip();

            AIGCServiceManager.getInstance().getAIGCService().pushSpeechDialogue(origin, Vad.UNKNOWN, false);
        }
        return false;
    }

    @Override
    public boolean onPlaybackAudioFrame(String channelId, int type, int samplesPerChannel,
                                        int bytesPerSample, int channels, int samplesPerSec, ByteBuffer buffer,
                                        long renderTimeMs, int avsync_type) {
        if (mIsSpeaking) {
            byte[] bytes = getSpeechVoiceData(buffer.capacity());

            if (null != bytes) {
                buffer.put(bytes, 0, buffer.capacity());
            }
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

    private void updateHistoryList(String newMessage, boolean showUi, String sid, boolean isAppend, boolean isAi) {
        runOnUiThread(new Runnable() {
            @Override
            public void run() {
                String date = mSdf.format(System.currentTimeMillis());
                if (isAi) {
                    Log.d(TAG, "[" + date + "] AI说：" + newMessage);
                } else {
                    Log.d(TAG, "[" + date + "]  " + newMessage);
                }

                boolean isNewLineMessage = true;
                int updateIndex = -1;
                if (!TextUtils.isEmpty(sid)) {
                    for (HistoryModel historyModel : mHistoryDataList) {
                        updateIndex++;
                        if (sid.equals(historyModel.getSid())) {
                            if (isAppend) {
                                historyModel.setMessage(historyModel.getMessage() + newMessage);
                            } else {
                                historyModel.setMessage(newMessage);
                            }
                            isNewLineMessage = false;
                            break;
                        }
                    }
                }
                if (showUi) {
                    if (isNewLineMessage) {
                        HistoryModel aiHistoryModel = new HistoryModel();
                        aiHistoryModel.setDate(date);
                        aiHistoryModel.setSid(sid);
                        if (isAi) {
                            aiHistoryModel.setMessage("AI]说：" + newMessage);
                        } else {
                            aiHistoryModel.setMessage(newMessage);
                        }
                        mHistoryDataList.add(aiHistoryModel);
                        if (null != mAiHistoryListAdapter) {
                            mAiHistoryListAdapter.notifyItemInserted(mHistoryDataList.size() - 1);
                            binding.aiHistoryList.scrollToPosition(mAiHistoryListAdapter.getDataList().size() - 1);
                        }
                    } else {
                        if (null != mAiHistoryListAdapter) {
                            mAiHistoryListAdapter.notifyItemChanged(updateIndex);
                            binding.aiHistoryList.scrollToPosition(mAiHistoryListAdapter.getDataList().size() - 1);
                        }
                    }
                }
            }
        });
    }
}
