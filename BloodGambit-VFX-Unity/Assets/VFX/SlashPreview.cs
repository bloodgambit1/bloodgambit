using UnityEngine;
public class SlashPreview : MonoBehaviour {
    public Transform ribbon;
    float time;
    Material material;
    void Start() { material = ribbon.GetComponentInChildren<Renderer>().material; }
    void Update() {
        time += Time.deltaTime;
        float t = time % 1.0f;
        ribbon.gameObject.SetActive(t < .26f);
        ribbon.localRotation = Quaternion.Euler(0, Mathf.Lerp(-30,30,t/.26f),0);
        material.SetColor("_TintColor", new Color(1,.22f,.035f, Mathf.Clamp01(1-t/.26f)));
    }
}
