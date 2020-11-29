using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UpdateShader : MonoBehaviour
{
    public Transform lightTransform;
    public Material material;

    private ComputeBuffer _buffer;
    private int amountOfSpheres;
    private static readonly int LightPos = Shader.PropertyToID("_LightPos");
    private static readonly int Spheres = Shader.PropertyToID("spheres");
    private static readonly int NumberOfSpheres = Shader.PropertyToID("numberOfSpheres");

    void Update()
    {
        Vector3 lightPosition = lightTransform.position;
        material.SetVector(LightPos, new Vector4(lightPosition.x, lightPosition.y, lightPosition.z, 1.0f));
    }

    void Start()
    {
        GameObject[] objects = GameObject.FindGameObjectsWithTag("Element");
        amountOfSpheres = objects.Length;
        Vector4[] spheres = new Vector4[amountOfSpheres];
        for (int i = 0; i < amountOfSpheres; i++)
        {
            Transform transform = objects[i].transform;
            
            spheres[i] = new Vector4(transform.position.x, transform.position.y, transform.position.z, transform.localScale.x);
            objects[i].GetComponent<MeshRenderer>().enabled = false;
        }
        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Vector4));
        _buffer = new ComputeBuffer(amountOfSpheres, stride, ComputeBufferType.Default);
        _buffer.SetData(spheres);
        material.SetBuffer (Spheres, _buffer);
        material.SetInt(NumberOfSpheres, amountOfSpheres);
    }

    private void OnDestroy()
    {
        _buffer.Release();
    }
}