package io.agora.aigc_service_example;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;

import androidx.annotation.Nullable;

import io.agora.aigic_service_example.databinding.MainActivityBinding;


public class MainActivity extends Activity {
    private final String TAG = "AIGCService-" + MainActivity.class.getSimpleName();
    private MainActivityBinding binding;


    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = MainActivityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        binding.btnGo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MainActivity.this, AIRobotActivity.class);
                startActivity(intent);
            }
        });
    }


}
