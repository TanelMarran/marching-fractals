using System;
using UnityEngine;
using UnityEngine.UI;

public class UpdateShader : MonoBehaviour
{
    public static Transform lightTransform;
    public Material material;

    private ComputeBuffer _buffer;
    private int amountOfSpheres;
    private GameObject[] sphereObjects;
    private static readonly int LightDir = Shader.PropertyToID("_LightDir");
    private static readonly int Spheres = Shader.PropertyToID("spheres");
    private static readonly int NumberOfSpheres = Shader.PropertyToID("numberOfSpheres");
    private static readonly int Power = Shader.PropertyToID("POWER");
    private static readonly int Color = Shader.PropertyToID("_Color");
    private static readonly int CurrentTime = Shader.PropertyToID("_CurrentTime");

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
        material.SetColor(Color, col);
    }


    void Update()
    {
        material.SetVector(LightDir, -lightTransform.forward);
        material.SetInt(NumberOfSpheres, amountOfSpheres);
        material.SetFloat(Power, Mathf.Sin(Time.time * Mathf.Deg2Rad * 8) * 2 + 8);
        material.SetFloat(CurrentTime, Time.time);

        if (material.name != "RaymarchShadows")
        {
            UpdateBuffer();
        }
    }

    void UpdateBuffer()
    {
        sphereObjects = GameObject.FindGameObjectsWithTag("Element");
        amountOfSpheres = sphereObjects.Length;
        Vector4[] spheres = new Vector4[amountOfSpheres];
        for (int i = 0; i < amountOfSpheres; i++)
        {
            Transform transform = sphereObjects[i].transform;

            spheres[i] = new Vector4(transform.position.x, transform.position.y, transform.position.z,
                transform.localScale.x);
        }

        _buffer.SetData(spheres);
        material.SetBuffer(Spheres, _buffer);
    }

    void Start()
    {
        lightTransform = GameObject.FindGameObjectWithTag("Light").transform;
        S_red = GameObject.FindGameObjectWithTag("slider_red").GetComponent<Slider>();
        S_green = GameObject.FindGameObjectWithTag("slider_green").GetComponent<Slider>();
        S_blue = GameObject.FindGameObjectWithTag("slider_blue").GetComponent<Slider>();

        Color col = new Color(red, green, blue, 1.0f);
        material.SetColor("_Color", col);

        if (material.name != "RaymarchShadows")
        {
            int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(Vector4));
            sphereObjects = GameObject.FindGameObjectsWithTag("Element");
            amountOfSpheres = sphereObjects.Length;
            _buffer = new ComputeBuffer(amountOfSpheres, stride, ComputeBufferType.Default);
        }
    }

    private void OnDestroy()
    {
        _buffer?.Release();
    }
}