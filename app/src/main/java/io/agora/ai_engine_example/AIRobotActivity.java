package io.agora.ai_engine_example;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.util.Log;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.ActivityCompat;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStream;
import java.util.Arrays;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.LinkedBlockingDeque;
import java.util.concurrent.ThreadPoolExecutor;
import java.util.concurrent.TimeUnit;

import io.agora.ai.sdk.AIEngine;
import io.agora.ai.sdk.AIEngineAction;
import io.agora.ai.sdk.AIEngineCallback;
import io.agora.ai.sdk.AIEngineCode;
import io.agora.ai.sdk.AIRole;
import io.agora.ai.sdk.Constants;
import io.agora.ai.sdk.Data;
import io.agora.ai_engine_example.databinding.AiRobotActivityBinding;

public class AIRobotActivity extends Activity implements AIEngineCallback {
    private final String TAG = "AIEngine" + AIRobotActivity.class.getSimpleName();
    private AiRobotActivityBinding binding;
    private AIEngine mAiEngine;

    private TextureView mTextureView = null;

    private final static String CHANNEL_ID = "testAgoraSDK";

    private boolean mIsSpeaking = false;
    private boolean mVoiceChangeEnable = false;
    private boolean mDownload = false;
    private boolean mMute = false;
    private String mLanguage = Constants.LANG_ZH_CN;
    private int mMaxRoleNum = 0;
    private int mCurrentRoleIndex = 0;
    private File mPcmFile;
    private OutputStream mPcmOs;
    private ExecutorService mExecutorCacheService;
    private ExecutorService mExecutorService;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = AiRobotActivityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        enableUi(false);
        initUnityView();
        initData();
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

    private void initUnityView() {
        mTextureView = new TextureView(this);
        mTextureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {
            @Override
            public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surfaceTexture, int i, int i1) {
                initAiEngine();
            }

            @Override
            public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surfaceTexture, int i, int i1) {
                Log.i(TAG, "onSurfaceTextureSizeChanged");
            }

            @Override
            public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surfaceTexture) {
                return false;
            }

            @Override
            public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surfaceTexture) {

            }
        });
        ViewGroup.LayoutParams layoutParams = new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
        binding.unity.addView(mTextureView, 0, layoutParams);

    }

    private void initAiEngine() {
        Log.i(TAG, "getSdkVersion:" + AIEngine.getSdkVersion());
        mAiEngine = new AIEngine.Builder(getApplicationContext())
                .callback(this)
                .enableLog(true, true)
                .initRtc(KeyCenter.getUserUid(), CHANNEL_ID, KeyCenter.APP_ID, KeyCenter.getRtcToken(CHANNEL_ID, KeyCenter.getUserUid()), KeyCenter.getRtmToken(KeyCenter.getUserUid()))
                //.textureView(mTextureView)
                //.activity(this)
                .userName("zhong")
                .language(Constants.LANG_ZH_CN)
                .enableChatConversation(false)
                .speechRecognitionFiltersLength(0)
                .build();

        mMaxRoleNum = mAiEngine.getAllAiRoles().length;
        Log.i(TAG, "getAllAiRoles:" + Arrays.toString(mAiEngine.getAllAiRoles()));
        AIRole aiRole = mAiEngine.getAllAiRoles()[0];
        aiRole.getAvatar().setBgFilePath("bg_ai_male.png");
        mAiEngine.setAiRole(aiRole);

        Log.i(TAG, "getCurrentAiRole:" + mAiEngine.getCurrentAiRole());

        Log.i(TAG, "allAvatarNames:" + Arrays.toString(mAiEngine.getAllAvatarNames()));

        //mAiEngine.checkDownloadRes();
        //mAiEngine.prepare();
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
                    if (mAiEngine != null) {
                        mAiEngine.stopVoiceChat();
                    }
                } else {
                    mIsSpeaking = true;
                    binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.end_speak));
                    if (mAiEngine != null) {
                        mAiEngine.startVoiceChat();
                    }
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
                mAiEngine.enableVoiceChange(mVoiceChangeEnable);
            }
        });

        binding.btnSwitchLang.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (Constants.LANG_ZH_CN.equals(mLanguage)) {
                    mLanguage = Constants.LANG_EN_US;
                    binding.btnSwitchLang.setText(R.string.lang_switch_cn);
                } else {
                    mLanguage = Constants.LANG_ZH_CN;
                    binding.btnSwitchLang.setText(R.string.lang_switch_en);
                }
                mIsSpeaking = false;
                binding.btnSpeak.setText(AIRobotActivity.this.getResources().getString(R.string.start_speak));
                mAiEngine.stopVoiceChat();
                mAiEngine.setLanguage(mLanguage);
                mAiEngine.prepare();
            }
        });

        binding.btnExit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                enableUi(false);
                mAiEngine.releaseEngine();
            }
        });

        binding.btnDownload.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mDownload) {
                    mDownload = true;
                    mAiEngine.checkDownloadRes();
                    binding.btnDownload.setText(R.string.cancel_download);
                } else {
                    mDownload = false;
                    mAiEngine.cancelDownloadRes();
                    binding.btnDownload.setText(R.string.download);
                }
            }
        });


        binding.btnMute.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!mMute) {
                    mMute = true;
                    mAiEngine.mute(true);
                    binding.btnMute.setText(R.string.unmute);
                } else {
                    mMute = false;
                    mAiEngine.mute(false);
                    binding.btnMute.setText(R.string.mute);
                }
            }
        });

        binding.btnSwitchAiRole.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mAiEngine.setAiRole(mAiEngine.getAllAiRoles()[mCurrentRoleIndex++ % mMaxRoleNum]);
            }
        });
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onDownloadResProgress(int progress, int index, int count) {
        Log.i(TAG, "onDownloadingRes: " + progress + " " + index + " " + count);
    }

    @Override
    public void onEngineResult(@NonNull AIEngineAction aiEngineAction, @NonNull AIEngineCode aiEngineCode, @Nullable String extraInfo) {
        Log.i(TAG, "onEngineResult: " + aiEngineAction + " " + aiEngineCode + ",extraInfo:" + extraInfo);
        if (AIEngineAction.DOWNLOAD == aiEngineAction) {
            if (AIEngineCode.SUCCESS == aiEngineCode) {
                mAiEngine.setTexture(mTextureView);
                mAiEngine.setActivity(AIRobotActivity.this);
                mAiEngine.prepare();
                runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        binding.btnDownload.setText(R.string.download);
                        binding.btnDownload.setEnabled(false);
                    }
                });
            } else if (AIEngineCode.DOWNLOAD_RES == aiEngineCode) {
                mAiEngine.downloadRes();
            }
        } else if (AIEngineAction.PREPARE == aiEngineAction && AIEngineCode.SUCCESS == aiEngineCode) {
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    enableUi(true);
                }
            });
        } else if (AIEngineAction.RELEASED == aiEngineAction && AIEngineCode.SUCCESS == aiEngineCode) {
            mAiEngine = null;
            runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    enableUi(false);
                    exit();
                }
            });
        }
    }

    private void exit() {
        Log.i(TAG, "exit");
        try {
            mPcmOs.close();
        } catch (Exception e) {
            e.printStackTrace();
        }
        mDownload = false;
        initAiEngine();
        binding.btnDownload.setEnabled(true);
    }

    @Override
    public void onSpeech2TextResult(String sid, Data<String> result) {
        Log.i(TAG, "onSpeech2TextResult: " + sid + " " + result.getData());
        mExecutorCacheService.execute(new Runnable() {
            @Override
            public void run() {
                if (mPcmFile.exists()) {
                    //mPcmFile.delete();
                }
            }
        });

    }

    @Override
    public void onLLMAnswer(String sid, Data<String> answer) {
        Log.i(TAG, "onLlmResult: " + sid + " " + answer.getData());
    }

    @Override
    public void onText2SpeechResult(String sid, Data<byte[]> voice) {
        Log.i(TAG, "onText2SpeechResult: " + sid);
        mExecutorService.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    mPcmOs.write(voice.getData(), 0, voice.getData().length);
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
