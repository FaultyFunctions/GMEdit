package file.kind.yy;
import ace.extern.AceAutoCompleteItem;
import gml.GmlAPI;
import gml.Project;
import gml.file.GmlFile;
import js.html.DivElement;
import js.lib.RegExp;
import ui.treeview.TreeView;
import yy.*;
using tools.NativeString;

/**
 * We don't know what this is but we'll find out
 * Indexing phase only
 * @author YellowAfterlife
 */
class KYyUnknown extends FileKind {
	public static var inst:KYyUnknown = new KYyUnknown();
	
	static var rxParentPath:RegExp = new RegExp(
		'\n  "parent":\\s*\\{'
		+ '[^}]*"path":\\s*"([^"]+)\\.yy"'
	);
	override public function index(path:String, content:String, main:String):Bool {
		var mtParentPath = rxParentPath.exec(content);
		var resource:YyResource = null;
		var parentPath:String = {
			var mt = rxParentPath.exec(content);
			if (mt != null) {
				resource = YyJson.parse(content);
				resource.parent.path;
			} else mt[1];
		}
		var detect = KYy.inst.detect(path, resource != null ? resource : parentPath);
		//
		if (parentPath.endsWith(".yy")) {
			parentPath = parentPath.substring(0, parentPath.length - 3);
		}
		//
		var resType = resource.resourceType;
		Project.current.yyResourceTypes[resource.name] = resType;
		//
		var dir = @:privateAccess YyLoader.folderMap[parentPath];
		if (dir == null) dir = cast TreeView.find(false, { rel: parentPath });
		//
		var full = Project.current.fullPath(path);
		if (dir != null) {
			var makeEl = true;
			var kind = resType.substring(2).toLowerCase();
			var name = resource.name;
			switch (resType) {
				case "GMSprite", "GMTileSet", "GMSound", "GMPath",
					"GMScript", "GMShader", "GMFont", "GMTimeline",
					"GMObject", "GMRoom"
				: {
					GmlAPI.gmlKind.set(name, "asset." + kind);
					GmlAPI.gmlLookupText += name + "\n";
					var next = new AceAutoCompleteItem(name, kind);
					GmlAPI.gmlComp.push(next);
					GmlAPI.gmlAssetComp.set(name, next);
				};
			}
			switch (resType) {
				case "GMScript": {
					full = haxe.io.Path.withoutExtension(full) + ".gml";
					content = electron.FileWrap.readTextFileSync(full);
				};
				case "GMExtension": makeEl = false;
			}
			if (makeEl) {
				var item = TreeView.makeAssetItem(name, path, full, kind);
				item.yyOpenAs = detect.kind;
				@:privateAccess YyLoader.itemsToInsert.push({
					item: item,
					dir: dir
				});
				//TreeView.insertSorted(dir, item);
				switch (resType) {
					case "GMSprite": TreeView.setThumbSprite(full, name, item);
				}
			}
		} else Main.console.error('`$path` has missing parent `$parentPath`');
		return detect.kind.index(full, content, main);
	}
}
