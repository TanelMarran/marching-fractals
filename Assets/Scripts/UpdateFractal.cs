using System;
using UnityEngine;

public class UpdateFractal : MonoBehaviour
{
    public Transform lightTransform;
    public Material material;

    private Vector3 lightDirection;
    
    private static readonly int LightDir = Shader.PropertyToID("_LightDir");
    private static readonly int Power = Shader.PropertyToID("POWER");
    
    void Update()
    {
        lightDirection = -lightTransform.forward;
        
        material.SetVector(LightDir, new Vector4(lightDirection.x, lightDirection.y, lightDirection.z, 1.0f));
        UpdateBuffer();
    }

    void UpdateBuffer()
    {
        material.SetFloat(Power, Mathf.Sin(Time.time * Mathf.Deg2Rad * 8) * 2 + 8 );
    }

    void Start()
    {
        UpdateBuffer();
    }

    private void OnDestroy()
    {
        //_buffer?.Release();
    }
}