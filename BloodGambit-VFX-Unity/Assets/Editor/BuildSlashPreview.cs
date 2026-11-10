using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
public static class BuildSlashPreview {
    public static void Build() {
        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var root = new GameObject("Blood Slash Preview");
        var model = (GameObject)PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>("Assets/VFX/blood_slash.fbx"));
        model.transform.SetParent(root.transform, false);
        var mat = new Material(Shader.Find("Legacy Shaders/Particles/Additive"));
        mat.SetColor("_TintColor",new Color(1,.22f,.035f,1));
        AssetDatabase.CreateAsset(mat,"Assets/VFX/BloodSlash.mat");
        foreach (var renderer in model.GetComponentsInChildren<Renderer>()) renderer.sharedMaterial = mat;
        root.AddComponent<SlashPreview>().ribbon = model.transform;
        PrefabUtility.SaveAsPrefabAsset(root,"Assets/VFX/BloodSlash.prefab");
        var camera = new GameObject("Camera").AddComponent<Camera>();
        camera.transform.position = new Vector3(0,4,-5);
        camera.transform.LookAt(Vector3.zero);
        camera.clearFlags = CameraClearFlags.SolidColor;
        camera.backgroundColor = new Color(.018f,.025f,.045f);
        EditorSceneManager.SaveScene(UnityEngine.SceneManagement.SceneManager.GetActiveScene(),"Assets/VFX/SlashPreview.unity");
        AssetDatabase.SaveAssets();
    }
}
