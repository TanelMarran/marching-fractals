using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdateShader : MonoBehaviour
{
    public Transform lightTransform;
    public Material material;
    private static readonly int LightPos = Shader.PropertyToID("_LightPos");

    void Update()
    {
        Vector3 lightPosition = lightTransform.position;
        material.SetVector(LightPos, new Vector4(lightPosition.x, lightPosition.y, lightPosition.z, 1.0f));
    }
}