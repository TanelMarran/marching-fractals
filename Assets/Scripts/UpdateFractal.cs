using System;
using UnityEngine;
using UnityEngine.UI;

public class UpdateFractal : MonoBehaviour
{
    public static Transform lightTransform;
    public Material material;

    private static readonly int LightDir = Shader.PropertyToID("_LightDir");
    private static readonly int Power = Shader.PropertyToID("POWER");

    private float red = 0.1f;
    private float green = 0.5f;
    private float blue = 0.9f;
    private float surfDist = 0.001f;

    public Slider S_red;
    public Slider S_green;
    public Slider S_blue;
    public Slider S_surfDist;
    public Toggle toggleMovement;

    public void colorChanged()
    {
        red = S_red.value;
        green = S_green.value;
        blue = S_blue.value;
        Color col = new Color(red, green, blue, 1.0f);
        material.SetColor("_Color", col);
    }

    public void surfDistChanged()
    {
        surfDist = S_surfDist.value;
        material.SetFloat("SURF_DIST", surfDist);
    }

    void Update()
    {
        material.SetVector(LightDir, -lightTransform.forward);
        if (toggleMovement.isOn)
        {
            material.SetFloat(Power, Mathf.Sin(Time.time * Mathf.Deg2Rad * 8) * 2 + 8);
        }
    }

    void Start()
    {
        lightTransform = GameObject.FindGameObjectWithTag("Light").transform;
        S_red = GameObject.FindGameObjectWithTag("slider_red").GetComponent<Slider>();
        S_green = GameObject.FindGameObjectWithTag("slider_green").GetComponent<Slider>();
        S_blue = GameObject.FindGameObjectWithTag("slider_blue").GetComponent<Slider>();
        S_surfDist = GameObject.FindGameObjectWithTag("slider_surf_dist").GetComponent<Slider>();
        toggleMovement = GameObject.FindGameObjectWithTag("toggle_movement").GetComponent<Toggle>();

        Color col = new Color(red, green, blue, 1.0f);
        material.SetColor("_Color", col);
        surfDist = S_surfDist.value;
        material.SetFloat("SURF_DIST", surfDist);
    }
}