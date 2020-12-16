using System;
using UnityEngine;

[ExecuteInEditMode]
public class UpdateShader : MonoBehaviour
{
    public Transform lightTransform;
    public Material material;

    private Vector3 lightDirection;

    private ComputeBuffer _buffer;
    private int amountOfSpheres;
    private GameObject[] sphereObjects;
    private static readonly int LightDir = Shader.PropertyToID("_LightDir");
    private static readonly int Spheres = Shader.PropertyToID("spheres");
    private static readonly int NumberOfSpheres = Shader.PropertyToID("numberOfSpheres");
    
    void Update()
    {
        lightDirection = -lightTransform.forward;
        
        material.SetVector(LightDir, new Vector4(lightDirection.x, lightDirection.y, lightDirection.z, 1.0f));
        UpdateBuffer();
    }

    void UpdateBuffer()
    {
        sphereObjects = GameObject.FindGameObjectsWithTag("Element");
        amountOfSpheres = sphereObjects.Length;
        Vector4[] spheres = new Vector4[amountOfSpheres];
        for (int i = 0; i < amountOfSpheres; i++)
        {
            Transform transform = sphereObjects[i].transform;
            
            spheres[i] = new Vector4(transform.position.x, transform.position.y, transform.position.z, transform.localScale.x);
        }
        _buffer.SetData(spheres);
        material.SetBuffer (Spheres, _buffer);
        material.SetInt(NumberOfSpheres, amountOfSpheres);
    }

    void Start()
    {
        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Vector4));
        sphereObjects = GameObject.FindGameObjectsWithTag("Element");
        amountOfSpheres = sphereObjects.Length;
        _buffer = new ComputeBuffer(amountOfSpheres, stride, ComputeBufferType.Default);
        UpdateBuffer();
    }

    private void OnDestroy()
    {
        //_buffer?.Release();
    }
}