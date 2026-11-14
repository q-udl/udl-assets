part of 'main.dart';

/// Shared RV29 evidence picker. Selection remains in the form's transient
/// memory; proof is persisted only when the corresponding event commits.
Widget assetEvidencePicker({
  required BuildContext context,
  required String assetCode,
  required String title,
  required SelectedAssetPhoto? selected,
  required ValueChanged<SelectedAssetPhoto> onSelected,
  required VoidCallback onRemove,
  required String testKey,
}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFFF8FAFD),
      border: Border.all(color: border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title + ' *',
          style: const TextStyle(fontWeight: FontWeight.w800,
            color: ink, fontSize: 13)),
        const SizedBox(height: 4),
        Text(assetCode + ' · minimal satu foto aktual per unit aset',
          style: const TextStyle(color: muted, fontSize: 11.5)),
        const SizedBox(height: 12),
        if (selected == null)
          Container(
            height: 105,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: Colors.white,
              border: Border.all(color: border)),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                  size: 30, color: muted),
                SizedBox(height: 5),
                Text('Belum ada foto bukti',
                  style: TextStyle(color: muted, fontSize: 12)),
              ]),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Container(
              color: Colors.white,
              child: Image.memory(
                selected.bytes, height: 150, fit: BoxFit.contain),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 7),
          Text(selected.fileName,
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: muted, fontSize: 11.5)),
        ],
        const SizedBox(height: 12),
        Builder(builder: (anchor) => OutlinedButton.icon(
          key: ValueKey(testKey),
          style: assetOutlinedStyle(AssetActionTone.informational),
          onPressed: () async {
            final photo = await AssetPhotoPicker.choose(
              context, anchorContext: anchor);
            if (photo != null && context.mounted) onSelected(photo);
          },
          icon: Icon(selected == null
            ? Icons.add_a_photo_outlined : Icons.autorenew_rounded,
            size: 18),
          label: Text(selected == null
            ? 'Tambah Foto Bukti' : 'Ganti Foto Bukti'),
        )),
        if (selected != null)
          Align(alignment: Alignment.centerRight,
            child: TextButton.icon(
              style: assetTextStyle(AssetActionTone.danger),
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Hapus pilihan foto')),
          ),
      ],
    ),
  );
}
