using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.SceneManagement;
using Random = UnityEngine.Random;

public class UI_Logic : MonoBehaviour
{
    public void changeScene()
    {
        int currentSceneIndex = SceneManager.GetActiveScene().buildIndex;
        int nextSceneIndex = ++currentSceneIndex;
        if (nextSceneIndex == SceneManager.sceneCountInBuildSettings)
        {
            nextSceneIndex = 0;
        }

        SceneManager.LoadScene(nextSceneIndex);
    }

    public void randomLightDirection()
    {
        Vector3 direction = Vector3.Normalize(Random.insideUnitSphere);
        direction.y = -Math.Abs(direction.y);
        UpdateShader.lightTransform.forward = direction;
    }
}