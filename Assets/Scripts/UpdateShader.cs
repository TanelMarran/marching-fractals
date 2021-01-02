using System;
using UnityEngine;
using UnityEngine.UI;

public class UpdateShader : MonoBehaviour
{
    public Transform lightTransform;
    public Material material;

    public static Vector3 lightDirection;

    private ComputeBuffer _buffer;
    private int amountOfSpheres;
    private GameObject[] sphereObjects;
    private static readonly int LightDir = Shader.PropertyToID("_LightDir");
    private static readonly int Spheres = Shader.PropertyToID("spheres");
    private static readonly int NumberOfSpheres = Shader.PropertyToID("numberOfSpheres");
    private static readonly int Power = Shader.PropertyToID("POWER");

    private float red = 0.1f;
    private float green = 0.5f;
    private float blue = 0.9f;

    public Slider S_red;
    public Slider S_green;
    public Slider S_blue;


    public void colorChanged()
    {
        red = S_red.value;
        green = S_green.value;
        blue = S_blue.value;
        Color col = new Color(red, green, blue, 1.0f);
        material.SetColor("_Color", col);
    }


    void Update()
    {
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
        material.SetFloat(Power, Mathf.Sin(Time.time * Mathf.Deg2Rad * 8) * 2 + 8 );
    }

    void Start()
    {
        Color col = new Color(red, green, blue, 1.0f);
        material.SetColor("_Color", col);
        lightDirection = -lightTransform.forward;
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